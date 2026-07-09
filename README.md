# 🚀 Proyecto Innovatech Chile - Orquestación en AWS EKS (EP3)

Este repositorio contiene el código fuente, los flujos de automatización CI/CD y los manifiestos de Kubernetes (IaC) para la plataforma de ventas y despachos de Innovatech Chile. El proyecto está construido bajo una arquitectura de microservicios y desplegado en **Amazon EKS (Elastic Kubernetes Service)** para garantizar alta disponibilidad y escalabilidad.

## 🏗️ Arquitectura del Sistema

La solución se compone de los siguientes microservicios y recursos:
* **Frontend:** Aplicación web estática servida mediante Nginx (Reverse Proxy), que actúa como Panel de Administración.
* **Backend Ventas:** API REST en Spring Boot (`ventas-app`) encargada de registrar las nuevas transacciones.
* **Backend Despachos:** API REST en Spring Boot (`despachos-app`) para la gestión logística y actualización de estados.
* **Base de Datos:** MySQL 8.0 (`tienda-db`) desplegada en el clúster para la persistencia de datos.

### Tecnologías Cloud & DevOps
* **Orquestación:** Amazon EKS (Kubernetes v1.34).
* **Registro de Contenedores:** Amazon ECR.
* **Autoscaling:** Horizontal Pod Autoscaler (HPA) configurado con Target Tracking al 50% de uso de CPU.
* **CI/CD:** GitHub Actions.
* **Monitoreo:** Amazon CloudWatch Observability & Metrics Server.

---

## 📋 Requisitos Previos

Para interactuar con el clúster o desplegar este proyecto localmente, necesitas tener instalado:
* **AWS CLI** configurado con credenciales válidas y permisos de IAM (ej. `LabRole`).
* **kubectl** para la gestión e interacción con el clúster de Kubernetes.
* **Git** para clonar el repositorio.

---

## 🛠️ Instrucciones de Instalación y Despliegue Manual

Si deseas desplegar la infraestructura de forma manual, los manifiestos declarativos se encuentran en el directorio `k8s/`. Sigue estos pasos:

### 1. Clonar el repositorio
```bash
git clone [https://github.com/tu-usuario/Devops.git](https://github.com/tu-usuario/Devops.git)
cd Devops
```

### 2. Autenticación con AWS EKS
Asegúrate de que tu terminal esté apuntando al clúster correcto actualizando tu contexto de `kubeconfig`:
```bash
aws eks update-kubeconfig --region us-east-1 --name eva3-eks
```

### 3. Aplicar Manifiestos de Kubernetes
Aplica los archivos en el siguiente orden estricto para evitar problemas de dependencias entre los recursos:

```bash
# 1. Crear el Namespace
kubectl apply -f k8s/namespace.yaml

# 2. Crear Secrets y Base de Datos
kubectl apply -f k8s/mysql-secret.yaml
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/mysql-service.yaml

# 3. Desplegar Backends (Ventas y Despachos)
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml

# 4. Configurar Autoscaling (HPA)
kubectl apply -f k8s/hpa.yaml

# 5. Desplegar Frontend y Proxy (LoadBalancer)
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
```

### 4. Obtener la IP Pública
Una vez desplegado todo, obtén la URL del Application Load Balancer (ALB) expuesto hacia internet para acceder al panel web:
```bash
kubectl get svc tienda-frontend -n tienda
```
Copia el valor de `EXTERNAL-IP` asignado por AWS y pégalo en tu navegador.

---

## ⚙️ Funcionamiento del Pipeline CI/CD

El proyecto cuenta con integración y entrega continua (CI/CD) a través de flujos automatizados en **GitHub Actions**. El proceso se activa automáticamente al realizar un `push` a la rama `deploy`.

**Flujo automatizado:**
1. **Checkout:** Clona el código fuente del repositorio.
2. **Autenticación:** Inyecta de forma segura las credenciales de AWS mediante los Secretos configurados en el repositorio (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`).
3. **Build & Push:** Construye las imágenes Docker y las almacena en Amazon ECR.
4. **Deploy:** Se conecta al clúster EKS, aplica los cambios en los manifiestos YAML y ejecuta un `kubectl rollout restart deployment/... -n tienda` para actualizar los Pods de la aplicación sin tiempo de inactividad.

---

## 📊 Monitoreo y Escalabilidad

* **Métricas y Logs:** El clúster está integrado nativamente con CloudWatch. Todos los logs de los contenedores (STDOUT/STDERR) y las métricas de rendimiento (API Server, CPU, RAM) son extraídos y centralizados automáticamente mediante Fluent Bit.
* **Auto-recuperación y Escalado:** El servicio cuenta con políticas de escalado dinámico. Si el tráfico en los backends supera el límite de CPU (50%), Kubernetes levanta nuevas réplicas (hasta un máximo de 5 pods) para soportar la carga, demostrando alta disponibilidad y tolerancia a fallos.
