# Imagen base optimizada para R
FROM rocker/r-ver:4.3.2

# 1. Reemplazar el repositorio por defecto por el mirror de US para evitar bloqueos
RUN sed -i 's/archive.ubuntu.com/us.archive.ubuntu.com/g' /etc/apt/sources.list \
    && sed -i 's/security.ubuntu.com/us.archive.ubuntu.com/g' /etc/apt/sources.list

# 1. Rewrite apt sources to HTTPS to bypass campus HTTP (port 80) blocking
RUN sed -i \
    -e 's|http://archive.ubuntu.com/ubuntu|https://us.archive.ubuntu.com/ubuntu|g' \
    -e 's|http://security.ubuntu.com/ubuntu|https://us.archive.ubuntu.com/ubuntu|g' \
    /etc/apt/sources.list

# 2. Instalar dependencias del sistema operativo
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

# Install all R packages including duckdb at the pinned version
RUN Rscript -e " \
    install.packages('remotes', repos = 'https://cloud.r-project.org'); \
    remotes::install_version( \
        'duckdb', \
        version = '1.5.2', \
        repos = 'https://cloud.r-project.org', \
        upgrade = 'never' \
    ); \
    install.packages(c( \
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
    ), repos = 'https://cloud.r-project.org'); \
    "

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