# Infrastructure as Code Tooling Comparison

Bachelor’s thesis project comparing **Terraform**, **Pulumi**, and **Ansible** in **local (non-cloud) environments**.

The study evaluates how these tools provision and manage identical Docker and Kubernetes setups, focusing outside of typical cloud-centric use cases. The goal is not to rank the tools, but to highlight **trade-offs and limitations** when applied to local infrastructure.

## Scope

- **Reproducibility**: consistency and provisioning time 
- **Portability**: cross-environment usability  
- **Maintainability**: code size, duplication and linting
- **State management**: state accuracy and recovery  
- **Drift detection**: detection and reconciliation of manual changes  


## Method

All tools provision the **same Docker and Kubernetes infrastructure**, differing only in IaC implementation.

- **Docker**: Docker Compose setup with a Spring Boot application and PostgreSQL database
- **Kubernetes**: Equivalent setup using manifests (namespace, ConfigMaps, Secrets, Deployment, StatefulSet, Services, Ingress) 

## Structure

### `main` branch

- All infrastructure configuration files for Terraform, Pulumi and Ansible 
- Implementations of identical Docker and Kubernetes setups 
- No generated metric outputs or analysis artifacts

### `maintainability` branch

- **CLOC (Count Lines of Code)** outputs (JSON format) 
- **JSCPD** reports for **code duplication** detection 
- **Linting and quality metrics**, where applicable
 
## Results

- **Terraform** offers the most predictable behavior for long-term infrastructure management due to its declarative model, persistent state, and drift detection.
- **Pulumi** provides similar accuracy with added flexibility through programming languages, but with higher runtime dependencies.
- **Ansible** excels in lightweight and highly portable setups, though its procedural approach and lack of persistent state limit its use for large or long-lived infrastructures.

Detailed results are documented in the thesis.