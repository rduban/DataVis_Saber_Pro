# Imagen base optimizada para R
FROM rocker/r-ver:4.3.2

# Reemplazar el repositorio por defecto por el mirror de US para evitar bloqueos
RUN sed -i 's/archive.ubuntu.com/us.archive.ubuntu.com/g' /etc/apt/sources.list \
    && sed -i 's/security.ubuntu.com/us.archive.ubuntu.com/g' /etc/apt/sources.list

# Instalar dependencias del sistema operativo requeridas para compilar/ejecutar los paquetes de R
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Instalar remotes, luego la versión exacta de duckdb (1.5.2), y finalmente el resto de paquetes
RUN Rscript -e "install.packages('remotes')" && \
    Rscript -e "remotes::install_version('duckdb', version = '1.5.2', repos = 'http://cran.us.r-project.org')" && \
    Rscript -e "install.packages(c( \
    'shiny', \
    'shinydashboard', \
    'shinyWidgets', \
    'plotly', \
    'DT', \
    'ggplot2', \
    'bslib', \
    'scales', \
    'DBI', \
    'glue', \
    'dplyr', \
    'stringdist', \
    'tidyr' \
))"

# Configurar el directorio de trabajo interno
RUN mkdir -p /app
WORKDIR /app

# Copiar el script de R y la base de datos local al contenedor
COPY app_2_3.R /app/app.R
COPY icfes.duckdb /app/

# Exponer el puerto en el que correrá la aplicación
EXPOSE 3838

# Ejecutar la aplicación Shiny apuntando a la red local del contenedor
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]