# =====================================
# LIBRERIAS
# =====================================

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(plotly)
library(DT)
library(ggplot2)
library(bslib)
library(scales)
library(DBI)
library(duckdb)
library(glue)
library(dplyr)
library(stringdist)
library(tidyr)

# =====================================
# CONEXION DUCKDB
# =====================================

con <- dbConnect(
  duckdb(),
  "icfes.duckdb",
  read_only = TRUE
)

# =====================================
# VARIABLES
# =====================================

competencias <- c(
  "Competencias ciudadanas"    = "mod_competen_ciudada_punt",
  "Comunicación escrita"       = "mod_comuni_escrita_punt",
  "Inglés"                     = "mod_ingles_punt",
  "Lectura crítica"            = "mod_lectura_critica_punt",
  "Razonamiento cuantitativo"  = "mod_razona_cuantitat_punt",
  "Puntaje global"             = "punt_global"
)

universidades <- dbGetQuery(
  con,
  "
  SELECT DISTINCT inst_nombre_institucion
  FROM icfes
  ORDER BY inst_nombre_institucion
  "
)[[1]]

anios <- dbGetQuery(
  con,
  "
  SELECT DISTINCT CAST(anio AS INTEGER) AS anio
  FROM icfes
  ORDER BY anio
  "
)$anio

# =====================================
# REGIONES GEOGRAFICAS COLOMBIA
# =====================================

regiones <- list(
  "Caribe"    = c("ATLANTICO", "BOLIVAR", "MAGDALENA", "CESAR",
                  "CORDOBA", "SUCRE", "LA GUAJIRA", "SAN ANDRES"),
  "Andina"    = c("ANTIOQUIA", "BOYACA", "CALDAS", "CUNDINAMARCA",
                  "HUILA", "NORTE DE SANTANDER", "QUINDIO",
                  "RISARALDA", "SANTANDER", "TOLIMA",
                  "BOGOTA D.C.", "BOGOTA"),
  "Pacifica"  = c("CAUCA", "CHOCO", "NARIÑO", "VALLE DEL CAUCA"),
  "Orinoquia" = c("ARAUCA", "CASANARE", "META", "VICHADA"),
  "Amazonia"  = c("AMAZONAS", "CAQUETA", "GUAINIA", "GUAVIARE",
                  "PUTUMAYO", "VAUPES"),
  "Insular"   = c("SAN ANDRES Y PROVIDENCIA")
)

get_region <- function(depto) {
  depto_up <- toupper(trimws(depto))
  for (region in names(regiones)) {
    if (depto_up %in% regiones[[region]]) return(region)
  }
  return(NA_character_)
}

get_depto_uni <- function(nombre_uni) {
  res <- dbGetQuery(
    con,
    glue("
      SELECT estu_inst_departamento
      FROM icfes
      WHERE inst_nombre_institucion = '{nombre_uni}'
      LIMIT 1
    ")
  )
  if (nrow(res) == 0) return(NA_character_)
  res[[1]]
}

# =====================================
# TEMA
# =====================================

tema <- bs_theme(
  version    = 5,
  bootswatch = "flatly",
  primary    = "#1F3C88",
  secondary  = "#95A5A6",
  base_font  = font_google("Roboto")
)

# =====================================
# UI
# =====================================

ui <- dashboardPage(

  skin = "blue",

  dashboardHeader(title = "ICFES Analytics"),

  dashboardSidebar(disable = TRUE),

  dashboardBody(

    theme = tema,

    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #F4F6F9;
        }
        .box {
          border-radius: 15px;
          box-shadow: 0px 2px 10px rgba(0,0,0,.08);
        }
      "))
    ),

    tabBox(
      width = 12,

      # =====================================
      # TAB COMPARACIONES
      # =====================================

      tabPanel(
        "Comparaciones",

        br(),

        # --- Controles ---
        fluidRow(

          column(
            4,
            pickerInput(
              "puntaje",
              "Competencia",
              choices  = competencias,
              selected = "punt_global",
              options  = list(`live-search` = TRUE)
            )
          ),

          column(
            4,
            pickerInput(
              "universidad",
              "Universidad",
              choices  = universidades,
              selected = "UNIVERSIDAD SERGIO ARBOLEDA-BARRANQUILLA.",
              options  = list(`live-search` = TRUE)
            )
          ),

          column(
            4,
            pickerInput(
              "universidad_extra",
              "Universidad adicional para comparar",
              choices  = c("(Ninguna)" = "", universidades),
              selected = "",
              options  = list(`live-search` = TRUE)
            )
          )
        ),

        # --- KPIs ---
        fluidRow(
          valueBoxOutput("media_box", width = 4),
          valueBoxOutput("n_box",     width = 4),
          valueBoxOutput("ic_box",    width = 4)
        ),

        # --- Gráfico líneas ---
        fluidRow(
          box(
            width       = 12,
            title       = "Comparación temporal",
            status      = "primary",
            solidHeader = TRUE,
            plotlyOutput("grafico", height = "500px")
          )
        ),

        # --- Gráfico barras ---
        fluidRow(
          box(
            width       = 12,
            title       = "Top programas",
            status      = "primary",
            solidHeader = TRUE,
            plotlyOutput("grafico_programas", height = "500px")
          )
        )
      ),

      # =====================================
      # TAB RANKING UNIVERSIDADES
      # =====================================

      tabPanel(
        "Ranking universidades",

        br(),

        fluidRow(

          column(
            4,
            pickerInput(
              "puntaje_ranking",
              "Competencia",
              choices  = competencias,
              selected = "punt_global"
            )
          ),

          column(
            4,
            pickerInput(
              "anio_ranking",
              "Año",
              choices  = sort(anios, decreasing = TRUE),
              selected = max(anios)
            )
          ),

          column(
            4,
            textInput(
              "uni_destacar",
              "Universidad a destacar",
              value = "UNIVERSIDAD SERGIO ARBOLEDA-BARRANQUILLA."
            )
          )
        ),

        fluidRow(
          box(
            width       = 12,
            title       = "Ranking universidades",
            status      = "warning",
            solidHeader = TRUE,
            plotlyOutput("ranking_uni", height = "850px")
          )
        )
      ),

      # =====================================
      # TAB RANKING PROGRAMAS
      # =====================================

      tabPanel(
        "Ranking programas",

        br(),

        fluidRow(

          column(
            4,
            textInput(
              "programa_busqueda",
              "Nombre programa",
              value = "PSICOLOGIA"
            )
          ),

          column(
            4,
            pickerInput(
              "region_programa",
              "Comparación",
              choices  = c("Nacional", "Caribe", "Atlantico"),
              selected = "Nacional"
            )
          ),

          column(
            4,
            pickerInput(
              "anio_programa",
              "Año",
              choices  = sort(anios, decreasing = TRUE),
              selected = max(anios)
            )
          )
        ),

        fluidRow(
          box(
            width       = 12,
            title       = "Ranking programas",
            status      = "info",
            solidHeader = TRUE,
            plotlyOutput("ranking_prog", height = "950px")
          )
        )
      )
    )
  )
)

# =====================================
# SERVER
# =====================================

server <- function(input, output, session) {

  # =====================================
  # DATOS RESUMEN (gráfico de líneas)
  # =====================================

  datos_resumen <- reactive({

    var       <- input$puntaje
    uni_sel   <- input$universidad
    uni_extra <- input$universidad_extra

    # Nombre corto para la leyenda: última palabra significativa del nombre
    nombre_corto <- function(nombre) {
      palabras <- strsplit(trimws(nombre), "\\s+")[[1]]
      # Quitar palabras genéricas del inicio
      stopwords <- c("UNIVERSIDAD", "CORPORACION", "FUNDACION",
                     "INSTITUCION", "ESCUELA", "INSTITUTO", "DE", "LA", "EL")
      sig <- palabras[!toupper(palabras) %in% stopwords]
      if (length(sig) == 0) sig <- palabras
      paste(sig[1:min(3, length(sig))], collapse = " ")
    }

    label_uni1 <- nombre_corto(uni_sel)

    # Región universidad principal
    depto_uni1  <- get_depto_uni(uni_sel)
    region_uni1 <- get_region(depto_uni1)

    misma_region <- TRUE
    label_uni2   <- NULL

    if (!is.null(uni_extra) && uni_extra != "") {
      depto_uni2  <- get_depto_uni(uni_extra)
      region_uni2 <- get_region(depto_uni2)
      misma_region <- !is.na(region_uni1) &&
                      !is.na(region_uni2) &&
                      region_uni1 == region_uni2
      label_uni2 <- nombre_corto(uni_extra)
    }

    # Universidad principal
    uni <- dbGetQuery(con, glue("
      SELECT
        CAST(anio AS INTEGER) AS anio,
        AVG({`var`})          AS media,
        STDDEV_SAMP({`var`})  AS sd,
        COUNT(*)              AS n,
        '{label_uni1}'        AS grupo
      FROM icfes
      WHERE inst_nombre_institucion = '{uni_sel}'
      GROUP BY anio
    "))

    # Nacional
    nacional <- dbGetQuery(con, glue("
      SELECT
        CAST(anio AS INTEGER) AS anio,
        AVG({`var`})          AS media,
        STDDEV_SAMP({`var`})  AS sd,
        COUNT(*)              AS n,
        'Nacional'            AS grupo
      FROM icfes
      GROUP BY anio
    "))

    datos <- list(uni, nacional)

    # Región (solo si ambas unis son de la misma o no hay segunda uni)
    if (!is.na(region_uni1) && misma_region) {
      deptos_sql <- paste0("'", regiones[[region_uni1]], "'", collapse = ", ")
      region_df  <- dbGetQuery(con, glue("
        SELECT
          CAST(anio AS INTEGER)    AS anio,
          AVG({`var`})             AS media,
          STDDEV_SAMP({`var`})     AS sd,
          COUNT(*)                 AS n,
          'Región {region_uni1}'   AS grupo
        FROM icfes
        WHERE estu_inst_departamento IN ({deptos_sql})
        GROUP BY anio
      "))
      datos <- c(datos, list(region_df))
    }

    # Universidad extra
    if (!is.null(uni_extra) && uni_extra != "") {
      extra_df <- dbGetQuery(con, glue("
        SELECT
          CAST(anio AS INTEGER) AS anio,
          AVG({`var`})          AS media,
          STDDEV_SAMP({`var`})  AS sd,
          COUNT(*)              AS n,
          '{label_uni2}'        AS grupo
        FROM icfes
        WHERE inst_nombre_institucion = '{uni_extra}'
        GROUP BY anio
      "))
      datos <- c(datos, list(extra_df))
    }

    bind_rows(datos) %>%
      mutate(
        anio   = as.numeric(anio),
        media  = as.numeric(media),
        sd     = as.numeric(sd),
        n      = as.numeric(n),
        se     = sd / sqrt(n),
        ic_inf = media - 1.96 * se,
        ic_sup = media + 1.96 * se
      )
  })

  # =====================================
  # KPI
  # =====================================

  output$media_box <- renderValueBox({
    # El grupo de la universidad principal es la primera fila distinta que NO es Nacional ni Región
    datos_uni <- datos_resumen() %>%
      filter(!grepl("^Nacional$|^Región", grupo)) %>%
      slice(1) %>%
      pull(grupo)
    d <- datos_resumen() %>% filter(grupo == datos_uni)
    valueBox(
      round(mean(d$media), 0),
      "Promedio universidad",
      icon  = icon("chart-line"),
      color = "blue"
    )
  })

  output$n_box <- renderValueBox({
    datos_uni <- datos_resumen() %>%
      filter(!grepl("^Nacional$|^Región", grupo)) %>%
      slice(1) %>%
      pull(grupo)
    d <- datos_resumen() %>% filter(grupo == datos_uni)
    valueBox(
      comma(sum(d$n)),
      "Número estudiantes",
      icon  = icon("users"),
      color = "green"
    )
  })

  output$ic_box <- renderValueBox({
    datos_uni <- datos_resumen() %>%
      filter(!grepl("^Nacional$|^Región", grupo)) %>%
      slice(1) %>%
      pull(grupo)
    d <- datos_resumen() %>% filter(grupo == datos_uni)
    valueBox(
      round(mean(d$ic_sup - d$ic_inf), 0),
      "Amplitud IC95%",
      icon  = icon("calculator"),
      color = "purple"
    )
  })

  # =====================================
  # GRAFICO LINEAS
  # =====================================

  output$grafico <- renderPlotly({

    datos <- datos_resumen()

    y_min <- min(120, floor(min(datos$ic_inf,  na.rm = TRUE)))
    y_max <- max(180, ceiling(max(datos$ic_sup, na.rm = TRUE)))

    p <- ggplot(
      datos,
      aes(
        x     = anio,
        y     = media,
        color = grupo,
        fill  = grupo,
        text  = paste0(grupo, ": ", round(media, 0))
      )
    ) +
      geom_ribbon(
        aes(ymin = ic_inf, ymax = ic_sup),
        alpha = .10,
        color = NA
      ) +
      geom_line(linewidth = 1.3) +
      geom_point(size = 2.5) +
      scale_y_continuous(labels = label_number(accuracy = 1)) +
      coord_cartesian(ylim = c(y_min, y_max)) +
      labs(color = NULL, fill = NULL) +
      theme_minimal(base_size = 14) +
      theme(
        legend.position  = "top",
        panel.grid.minor = element_blank()
      )

    ggplotly(p, tooltip = "text") %>%
      layout(legend = list(orientation = "h", x = 0, y = 1.1))
  })

  # =====================================
  # GRAFICO BARRAS: TOP PROGRAMAS
  # =====================================

  output$grafico_programas <- renderPlotly({

    var       <- input$puntaje
    uni_sel   <- input$universidad
    uni_extra <- input$universidad_extra

    tiene_extra <- !is.null(uni_extra) && uni_extra != ""

    if (!tiene_extra) {

      # Top 10 programas de la universidad principal
      datos_prog <- dbGetQuery(con, glue("
        SELECT
          estu_prgm_academico                AS programa,
          ROUND(AVG({`var`}), 0)             AS promedio,
          COUNT(*)                           AS n
        FROM icfes
        WHERE inst_nombre_institucion = '{uni_sel}'
        GROUP BY estu_prgm_academico
        HAVING COUNT(*) > 10
        ORDER BY promedio DESC
        LIMIT 10
      "))

      datos_prog <- datos_prog %>%
        mutate(
          programa  = stringr::str_to_title(tolower(programa)),
          promedio  = as.numeric(promedio)
        )

      p <- ggplot(
        datos_prog,
        aes(
          x    = reorder(programa, promedio),
          y    = promedio,
          text = paste0(programa, ": ", promedio)
        )
      ) +
        geom_col(fill = "#1F3C88") +
        geom_text(
          aes(label = promedio),
          hjust = -0.2,
          size  = 3.5
        ) +
        coord_flip() +
        scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
        labs(x = NULL, y = "Puntaje promedio") +
        theme_minimal(base_size = 12) +
        theme(panel.grid.minor = element_blank())

      ggplotly(p, tooltip = "text")

    } else {

      # Programas de cada universidad por separado
      prog_uni1 <- dbGetQuery(con, glue("
        SELECT
          estu_prgm_academico            AS programa,
          ROUND(AVG({`var`}), 0)         AS promedio,
          COUNT(*)                       AS n
        FROM icfes
        WHERE inst_nombre_institucion = '{uni_sel}'
        GROUP BY estu_prgm_academico
        HAVING COUNT(*) > 10
      "))

      prog_uni2 <- dbGetQuery(con, glue("
        SELECT
          estu_prgm_academico            AS programa,
          ROUND(AVG({`var`}), 0)         AS promedio,
          COUNT(*)                       AS n
        FROM icfes
        WHERE inst_nombre_institucion = '{uni_extra}'
        GROUP BY estu_prgm_academico
        HAVING COUNT(*) > 10
      "))

      # Matching aproximado: para cada programa de uni1 busca el más similar en uni2
      # usando distancia de Jaro-Winkler (tolera variaciones de escritura)
      if (!requireNamespace("stringdist", quietly = TRUE)) {
        install.packages("stringdist", quiet = TRUE)
      }

      p1 <- toupper(trimws(prog_uni1$programa))
      p2 <- toupper(trimws(prog_uni2$programa))

      # Matriz de distancias (método jw = Jaro-Winkler, entre 0=igual y 1=totalmente distinto)
      mat <- stringdist::stringdistmatrix(p1, p2, method = "jw")

      umbral <- 0.25   # similitud alta: menos del 15% de distancia

      matches <- apply(mat, 1, function(fila) {
        idx <- which.min(fila)
        if (fila[idx] <= umbral) idx else NA_integer_
      })

      validos <- !is.na(matches)

      if (sum(validos) == 0) {
        return(plotly_empty() %>%
          layout(title = "Sin programas similares entre las dos universidades"))
      }

      datos_prog <- data.frame(
        programa      = prog_uni1$programa[validos],
        promedio_uni1 = as.numeric(prog_uni1$promedio[validos]),
        promedio_uni2 = as.numeric(prog_uni2$promedio[matches[validos]])
      ) %>%
        arrange(desc(promedio_uni1)) %>%
        slice(1:min(10, n()))

      if (nrow(datos_prog) == 0) {
        return(plotly_empty() %>%
          layout(title = "Sin programas en común con n > 10"))
      }

      # Nombre corto de cada universidad para la leyenda
      nombre_corto <- function(nombre) {
        palabras <- strsplit(trimws(nombre), "\\s+")[[1]]
        stopwords <- c("UNIVERSIDAD", "CORPORACION", "FUNDACION",
                       "INSTITUCION", "ESCUELA", "INSTITUTO", "DE", "LA", "EL")
        sig <- palabras[!toupper(palabras) %in% stopwords]
        if (length(sig) == 0) sig <- palabras
        paste(sig[1:min(3, length(sig))], collapse = " ")
      }

      label1 <- nombre_corto(uni_sel)
      label2 <- nombre_corto(uni_extra)

      datos_long <- datos_prog %>%
        mutate(
          programa     = stringr::str_to_title(tolower(programa)),
          promedio_uni1 = as.numeric(promedio_uni1),
          promedio_uni2 = as.numeric(promedio_uni2)
        ) %>%
        tidyr::pivot_longer(
          cols      = c(promedio_uni1, promedio_uni2),
          names_to  = "universidad",
          values_to = "promedio"
        ) %>%
        mutate(
          universidad = ifelse(universidad == "promedio_uni1", label1, label2)
        )

      p <- ggplot(
        datos_long,
        aes(
          x    = reorder(programa, promedio),
          y    = promedio,
          fill = universidad,
          text = paste0(universidad, " - ", programa, ": ", promedio)
        )
      ) +
        geom_col(position = "dodge") +
        coord_flip() +
        scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
        labs(x = NULL, y = "Puntaje promedio", fill = NULL) +
        theme_minimal(base_size = 12) +
        theme(
          legend.position  = "top",
          panel.grid.minor = element_blank()
        )

      ggplotly(p, tooltip = "text") %>%
        layout(legend = list(orientation = "h", x = 0, y = 1.1))
    }
  })

  # =====================================
  # RANKING UNIVERSIDADES
  # =====================================

  output$ranking_uni <- renderPlotly({

    var      <- input$puntaje_ranking
    anio_sel <- input$anio_ranking

    ranking <- dbGetQuery(con, glue("
      SELECT
        inst_nombre_institucion,
        ROUND(AVG({`var`}), 0) AS promedio,
        COUNT(*) AS n
      FROM icfes
      WHERE CAST(anio AS INTEGER) = {anio_sel}
      GROUP BY inst_nombre_institucion
      HAVING COUNT(*) > 30
      ORDER BY promedio DESC
    "))

    ranking$posicion <- seq_len(nrow(ranking))

    top12 <- ranking %>% slice(1:12)

    uni_extra_rank <- ranking %>%
      filter(grepl(input$uni_destacar, inst_nombre_institucion, ignore.case = TRUE))

    ranking_final <- bind_rows(top12, uni_extra_rank) %>%
      distinct(inst_nombre_institucion, .keep_all = TRUE) %>%
      mutate(
        etiqueta  = paste0("#", posicion, " - ", inst_nombre_institucion),
        categoria = ifelse(
          grepl(input$uni_destacar, inst_nombre_institucion, ignore.case = TRUE),
          "Destacada", "Top"
        )
      )

    p <- ggplot(
      ranking_final,
      aes(
        x    = reorder(etiqueta, promedio),
        y    = promedio,
        fill = categoria,
        text = paste0(
          "<b>", inst_nombre_institucion, "</b>",
          "<br>Posición: ", posicion,
          "<br>Promedio: ", promedio
        )
      )
    ) +
      geom_col() +
      coord_flip() +
      theme_minimal(base_size = 11) +
      theme(
        axis.text.y      = element_text(size = 8),
        legend.position  = "top",
        panel.grid.minor = element_blank()
      )

    ggplotly(p, tooltip = "text")
  })

  # =====================================
  # RANKING PROGRAMAS
  # =====================================

  output$ranking_prog <- renderPlotly({

    var      <- input$puntaje
    anio_sel <- input$anio_programa

    filtro_region <- switch(
      input$region_programa,
      "Caribe" = "
        AND estu_inst_departamento IN (
          'ATLANTICO','BOLIVAR','MAGDALENA','CESAR',
          'CORDOBA','SUCRE','LA GUAJIRA'
        )
      ",
      "Atlantico" = "
        AND estu_inst_departamento = 'ATLANTICO'
      ",
      ""
    )

    consulta <- glue("
      SELECT
        estu_prgm_academico,
        inst_nombre_institucion,
        ROUND(AVG({`var`}), 0) AS promedio,
        COUNT(*) AS n
      FROM icfes
      WHERE
        UPPER(estu_prgm_academico) LIKE UPPER('%{input$programa_busqueda}%')
        AND CAST(anio AS INTEGER) = {anio_sel}
        {filtro_region}
      GROUP BY estu_prgm_academico, inst_nombre_institucion
      HAVING COUNT(*) > 20
      ORDER BY promedio DESC
      LIMIT 25
    ")

    ranking <- dbGetQuery(con, consulta)
    ranking$posicion <- seq_len(nrow(ranking))

    ranking <- ranking %>%
      mutate(
        etiqueta  = paste0("#", posicion, " - ", inst_nombre_institucion),
        categoria = ifelse(
          grepl("SERGIO", inst_nombre_institucion, ignore.case = TRUE),
          "Sergio", "Comparación"
        )
      )

    p <- ggplot(
      ranking,
      aes(
        x    = reorder(etiqueta, promedio),
        y    = promedio,
        fill = categoria,
        text = paste0(
          "<b>", estu_prgm_academico, "</b>",
          "<br>", inst_nombre_institucion,
          "<br>Posición: ", posicion,
          "<br>Promedio: ", promedio
        )
      )
    ) +
      geom_col() +
      coord_flip() +
      theme_minimal(base_size = 11) +
      theme(
        axis.text.y      = element_text(size = 8),
        legend.position  = "top",
        panel.grid.minor = element_blank()
      )

    ggplotly(p, tooltip = "text")
  })
}

# =====================================
# APP
# =====================================

shinyApp(ui, server)
