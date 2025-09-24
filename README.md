# Orthanc Python + Configuración Reproducible

Este proyecto levanta un servidor **Orthanc con soporte Python y plugins**, empaquetado en Docker.
La configuración para cada instalación se centraliza en **un solo archivo externo (`env`)**.
Incluye un wrapper `up.sh` para usar ese mismo `env` tanto en Docker Compose (puertos/nombre)
como dentro del contenedor (Orthanc).

---

## 📂 Estructura del proyecto

```
.
├── config/
│   ├── orthanc.tpl.json        # Plantilla base de configuración Orthanc
│   └── connections.local.json  # (opcional) Conexiones locales por sitio
├── docker/
│   └── Dockerfile.python       # Imagen personalizada basada en Orthanc Python (FROM pinneado por digest)
├── docker-compose.yml          # Orquestación con Docker Compose
├── env                         # Configuración editable por cada instalación (único archivo a tocar)
├── scripts/
│   └── entrypoint.sh           # Renderiza config + merge de conexiones
├── python/
│   └── plugins/                # (opcional) Plugins Python propios
├── storage/                    # Datos persistentes de Orthanc
├── worklists/                  # Worklist DB (opcional)
├── logs/                       # Logs de Orthanc
├── up.sh                       # Wrapper: exporta `env` + docker compose up
└── down.sh                     # Wrapper: exporta `env` + docker compose down
```

---

## 🚀 Pasos para construir desde cero

### 1) Clonar el repositorio
```bash
git clone https://github.com/superegi/Orthanc_py/ orthanc-python
cd orthanc-python
```

### 2) Editar **solo** el archivo `env`
Valores de ejemplo (ajusta según tu instalación):
```ini
COMPOSE_PROJECT_NAME=ortest       # minúsculas, letras/números, guiones o guion_bajo
TZ=America/Santiago

ORTHANC_NAME="Orthanc Python IA"  # poner comillas si hay espacios o '/'
ORTHANC_USERNAME=user
ORTHANC_PASSWORD=1234
ORTHANC_AET=ORTHANC_TEST
ORTHANC_MAX_ASSOC=8

HTTP_PORT=8045                    # puerto HTTP del host → contenedor 8042
DICOM_PORT=4245                   # puerto DICOM del host → contenedor 4242
```

> **Notas**
> - Si usas espacios o `/` en `ORTHANC_NAME`, debes poner el valor **entre comillas**.
> - `COMPOSE_PROJECT_NAME` debe estar en **minúsculas** (regla de Docker Compose).

### 3) Levantar el entorno
```bash
chmod +x up.sh
./up.sh
```

### 4) Verificar que Orthanc está corriendo
```bash
docker ps --format "table {{.Names}}	{{.Ports}}	{{.Status}}"
curl -u user:1234 http://localhost:${HTTP_PORT}/system | jq .
curl -u user:1234 http://localhost:${HTTP_PORT}/plugins
```

Debes ver información del sistema y la lista de plugins cargados (`dicom-web`, `explorer2`, `webviewer`, `python`, etc.).

---

## 🔌 Conexiones locales (opcional)
Define destinos DICOM, Orthanc Peers o DICOMweb en `config/connections.local.json`.
Si este archivo existe, se **fusiona automáticamente** con la configuración base al arrancar.

Ejemplo mínimo:
```json
{
  "DicomModalities": {
    "Hospital": { "Host": "10.1.1.50", "Port": 11112, "AET": "HOSPITAL_AE" }
  },
  "OrthancPeers": {
    "VPN": [ "http://xxxxxxxxxxx/", "xxxx", "xxxx" ]
  },
  "DicomWeb": {
    "Servers": {
      "WADO-ACTUAL": [ "http://xx.xx.xx.xx/dicom-web/", "xxxx", "xxxx" ]
    }
  }
}
```

### Verificación por API REST
```bash
curl -u user:1234 http://localhost:${HTTP_PORT}/modalities | jq .
curl -u user:1234 http://localhost:${HTTP_PORT}/peers | jq .
curl -u user:1234 http://localhost:${HTTP_PORT}/dicom-web/servers | jq .
```

> La UI web (Explorer) no muestra estas listas por defecto; se consultan por API o con extensiones.

---

## 🧩 Detalles técnicos

- **Imagen base fijada por digest** (reproducible): `jodogne/orthanc-python@sha256:<DIGEST>` (ver `docker/Dockerfile.python`).
- **Plugins**: la imagen trae `.so` en `/usr/local/share/orthanc/plugins`. En `orthanc.tpl.json` usamos:
  ```json
  "Plugins": [ "/usr/local/share/orthanc/plugins" ],
  "RemoteAccessAllowed": true
  ```
- **Fusión dinámica de configuración** en `scripts/entrypoint.sh`:
  - Render con `envsubst` de `orthanc.tpl.json` → `/etc/orthanc/orthanc.base.json`
  - Si existe `config/connections.local.json`, se renderiza y se fusiona con `jq` → `/etc/orthanc/orthanc.json`
  - Si no existe, se usa la base directamente.

---

## 🧯 Troubleshooting rápido

- **No responde `http://localhost:${HTTP_PORT}`**
  Verifica el mapeo de puertos:
  ```bash
  docker port ${COMPOSE_PROJECT_NAME}-orthanc
  ```
  Debe mostrar `8042 -> ${HTTP_PORT}`. Si no, corre `./up.sh` (que exporta `env`) y vuelve a levantar.

- **Credenciales no funcionan**
  Comprueba qué cargó Orthanc realmente:
  ```bash
  docker exec -it ${COMPOSE_PROJECT_NAME}-orthanc sh -lc 'sed -n "1,140p" /etc/orthanc/orthanc.json'
  ```

- **Conexiones vacías** (`[]`) en `/modalities`, `/peers`, `/dicom-web/servers`
  - Asegúrate de que **existe** `config/connections.local.json` en el host.
  - Confirma dentro del contenedor:
    ```bash
    docker exec -it ${COMPOSE_PROJECT_NAME}-orthanc sh -lc 'ls -l /config; sed -n "1,200p" /config/connections.local.json || true'
    docker exec -it ${COMPOSE_PROJECT_NAME}-orthanc sh -lc 'sed -n "1,200p" /etc/orthanc/orthanc.json'
    ```
  - Si no aparecen, revisa que tu `entrypoint.sh` sea el que hace el **merge con `jq`**.

---

## 🛑 Apagar el entorno
```bash
chmod +x down.sh
./down.sh
# o: docker compose down
```

---

## 📜 Licencia
GPLv3 (Orthanc es GPLv3
superegi!
