# -------------------------------------------------------------
# ETAPA 1: CONFIGURACIÓN DE IMAGEN BASE Y ARGUMENTOS
# -------------------------------------------------------------

# Define la versión de Node. Su uso antes de FROM permite que la imagen base sea dinámica.
ARG NODE_V=lts
FROM node:${NODE_V}-alpine

# Define el directorio de trabajo por defecto para la aplicación web
WORKDIR /usr/src/app

# -------------------------------------------------------------
# ETAPA 2: INSTALACIÓN DE DEPENDENCIAS (Optimización de Caché)
# -------------------------------------------------------------
# Copia solo los archivos de configuración de dependencias primero.
# Esto asegura que "npm install" solo se ejecute si cambian estos archivos.
COPY frontend-entrypoint /usr/local/bin/frontend-entrypoint

# Instala Angular CLI globalmente y luego las dependencias del proyecto.
# Esta es una capa que se aprovecha del caché de Docker si package.json no cambia.
RUN npm install -g @angular/cli && chmod +x /usr/local/bin/frontend-entrypoint

# -------------------------------------------------------------
# ETAPA 3: EXPOSICIÓN Y EJECUCIÓN
# -------------------------------------------------------------

# Expone el puerto por defecto de desarrollo de Angular/Node.js
EXPOSE 4200

# Define el comando principal que se ejecuta al iniciar el contenedor.
# Usar "--host 0.0.0.0" es crucial para que el servicio sea accesible
# desde fuera del contenedor a través del mapeo de puertos de Docker.
CMD ["frontend-entrypoint"]

# Comando opcional para mantener el contenedor en ejecución solo con fines de depuración:
#CMD ["sleep", "infinity"]
