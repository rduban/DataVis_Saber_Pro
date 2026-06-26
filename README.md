# DataVis Saber Pro 📊

Una aplicación web interactiva desarrollada en R (Shiny) para el análisis, visualización y comparación del desempeño histórico de las universidades y programas académicos en las pruebas ICFES en Colombia.

El proyecto utiliza DuckDB como motor de base de datos columnar local, garantizando un rendimiento excepcional en consultas complejas sobre grandes volúmenes de datos sin consumir excesiva memoria RAM.

🚀 Instalación y Despliegue con Docker

La forma más rápida y segura de correr este proyecto es a través de Docker. Esto asegura que todas las dependencias de R y del sistema operativo estén correctamente configuradas.

1. Requisitos previos

Tener Docker instalado en tu máquina.

Clonar este repositorio:

```sh
git clone https://github.com/rduban/DataVis_Saber_Pro
cd DataVis_Saber_Pro
```

(Asegúrate de que los archivos app.R, Dockerfile y icfes.duckdb se encuentren en la raíz de la carpeta).

2. Construir la imagen de Docker

Abre tu terminal en la ruta del proyecto y ejecuta el siguiente comando para construir la imagen. Este proceso instalará las librerías necesarias de R.

```sh
docker build -t icfes-analytics-app .
```

3. Ejecutar el contenedor

Una vez finalizada la construcción, levanta el contenedor mapeando el puerto 3838:

```sh
docker run -d -p 3838:3838 --name icfes-app icfes-analytics-app
```

4. Visualizar la aplicación

Abre tu navegador web preferido e ingresa a la siguiente dirección:
👉 http://localhost:3838

5. Visualización de errores

Ante cualquier eventualidad, los logs de error se pueden visualizar en:

```sh
docker logs icfes-app
```

🗺️ Roadmap

El proyecto está en constante evolución. Aquí hay un vistazo de hacia dónde nos dirigimos en futuras actualizaciones:

[ ] Módulo de predicción: Implementar modelos de regresión simples para estimar puntajes esperados basados en tendencias históricas.

[ ] Exportación de reportes: Habilitar un botón para descargar gráficos en alta calidad y reportes tabulares en formato PDF o Excel.

[ ] Automatización de ETL: Actualizar la base de datos icfes.duckdb con datos de años adicionales.

📄 Licencia

Este proyecto se distribuye bajo la Licencia MIT, lo que significa que eres libre de usar, modificar y distribuir el código, tanto para fines personales como comerciales. Para más detalles, consulta el archivo LICENSE incluido en este repositorio.