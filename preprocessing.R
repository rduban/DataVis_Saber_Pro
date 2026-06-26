#librerias

library(readr)
library(dplyr)
library(purrr)

# Obtener lista de archivos CSV
archivos <- list.files(
  pattern = "\\.txt$",
  full.names = TRUE
)

# variables de interes
identificacion<-c("estu_consecutivo","estu_inst_departamento","estu_prgm_academico","estu_snies_prgmacademico","estu_prgm_municipio","inst_nombre_institucion")

puntajes<-c("mod_competen_ciudada_punt","mod_comuni_escrita_punt","mod_ingles_punt",
            "mod_lectura_critica_punt","mod_razona_cuantitat_punt","punt_global")
variables <- c(identificacion, puntajes)

# Cargar todos los archivos en una lista
base_total <- archivos %>% 
  
  map(function(archivo){
    
    # Extraer año del nombre del archivo
    anio <- stringr::str_extract(basename(archivo), "\\d{4}")
    
    # Leer archivo
    datos <- read_delim(
      archivo,
      delim = ";",
      col_types = cols(.default = "c")
    )
    
    # Seleccionar variables y agregar año
    datos %>% 
      select(any_of(variables)) %>% 
      mutate(anio = anio)
    
  }) %>% 
  
  bind_rows()

# identificar a sergio BQ

base_total$inst_nombre_institucion<-  ifelse(base_total$inst_nombre_institucion=="UNIVERSIDAD SERGIO ARBOLEDA-BOGOTÁ D.C."&
                                               base_total$estu_prgm_municipio=="BARRANQUILLA","UNIVERSIDAD SERGIO ARBOLEDA-BARRANQUILLA.",
                                             base_total$inst_nombre_institucion)
base_total$estu_inst_departamento<-  ifelse(base_total$inst_nombre_institucion=="UNIVERSIDAD SERGIO ARBOLEDA-BARRANQUILLA.","ATLANTICO",
                                             base_total$estu_inst_departamento)
#saveRDS(base_total, "Saber_Pro/base_total.rds")
#library(arrow)
#write_parquet(base_total, "Saber_Pro/base_total.parquet")

base_total <- base_total %>%
  
  mutate(
    
    across(
      c(
        mod_competen_ciudada_punt,
        mod_comuni_escrita_punt,
        mod_ingles_punt,
        mod_lectura_critica_punt,
        mod_razona_cuantitat_punt,
        punt_global
      ),
      as.numeric
    )
    
  )

library(DBI)
library(duckdb)

con <- dbConnect(
  duckdb(),
  "icfes.duckdb"
)

dbWriteTable(
  con,
  "icfes",
  base_total,
  overwrite = TRUE
)


dbDisconnect(con, shutdown = TRUE)
#library(fst)
#write_fst(base_total, "Saber_Pro/base_total.fst")















