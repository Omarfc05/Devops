# 🚀 Proyecto Innovatech Chile - Orquestación en AWS EKS (EP3)

Este repositorio contiene el código fuente, los flujos de automatización CI/CD y los manifiestos de Kubernetes (IaC) para la plataforma de ventas y despachos de Innovatech Chile. El proyecto está construido bajo una arquitectura de microservicios y desplegado en **Amazon EKS (Elastic Kubernetes Service)** para garantizar alta disponibilidad y escalabilidad.

## 🏗️ Arquitectura del Sistema

La solución se compone de los siguientes microservicios:
* **Frontend:** Aplicación web estática servida mediante Nginx, que actúa como Panel de Administración.
* **Backend Ventas:** API REST en Spring Boot encargada de registrar las nuevas transacciones.
* **Backend Despachos:** API REST en Spring Boot para la gestión logística y actualización de estados.
* **Base de Datos:** MySQL 8.0 desplegada en el clúster para la persistencia de datos.

### Tecnologías Cloud & DevOps
* **Orquestación:** Amazon EKS (Kubernetes v1.34).
* **Registro de Contenedores:** Amazon ECR.
* **Autoscaling:** Horizontal Pod Autoscaler (HPA) configurado al 50% de uso de CPU.
* **CI/CD:** GitHub Actions.
* **Monitoreo:** Amazon CloudWatch Observability & Metrics Server.

---

## 📋 Requisitos Previos

Para interactuar con el clúster o desplegar este proyecto localmente, necesitas tener instalado:
* [AWS CLI](https://aws.amazon.com/cli/) configurado con credenciales válidas.
* [kubectl](https://kubernetes.io/docs/tasks/tools/) para la gestión de Kubernetes.
* [Docker](https://www.docker.com/) para construcción local de imágenes (opcional).
* Git.

---

## 🛠️ Instrucciones de Instalación y Despliegue Manual

Si deseas desplegar la infraestructura de forma manual en tu propio clúster EKS, sigue estos pasos:

### 1. Clonar el repositorio
```bash
git clone [https://github.com/tu-usuario/Devops.git](https://github.com/tu-usuario/Devops.git)
cd Devops
