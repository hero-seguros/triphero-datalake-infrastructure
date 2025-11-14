# TripHero Datalake Infrastructure

Infraestrutura como código para o Datalake TripHero usando Terraform, MSK (Kafka) e Debezium.

## 📋 Arquitetura

- **VPC Peering**: Conecta sa-east-1 (RDS) ↔ us-east-2 (MSK/EKS)
- **Amazon MSK**: Cluster Kafka gerenciado (2 brokers t3.small, Kafka 3.9.0)
- **IAM Roles**: IRSA para Debezium com acesso a MSK e Secrets Manager
- **Security**: TLS em trânsito, SASL/IAM authentication, encryption at rest
- **Monitoring**: CloudWatch Logs para MSK
- **Debezium**: CDC para capturar mudanças de read-replicas

> **Nota**: Destino final (S3/Redshift) será definido posteriormente

## 🏗️ Componentes

### VPC Peering (Cross-Region)
- **Requester**: vpc-0f41b5d828db40753 (us-east-2, 10.20.0.0/16)
- **Accepter**: vpc-41df3927 (sa-east-1, 172.31.0.0/16)
- **Latency**: ~120-150ms
- **Data Transfer**: $0.02/GB
- **Uso**: Conecta RDS (sa-east-1) ao MSK/Debezium (us-east-2)

### Amazon MSK (Kafka)
- Kafka Version: **3.9.0**
- Broker Nodes: **2x kafka.t3.small** (inicial, escala depois)
- EBS Volume: **100 GB** por broker
- Authentication: **SASL/IAM**
- Encryption: **TLS** (in-transit e at-rest)
- Replication Factor: **2** (inicial)
- Min In-Sync Replicas: **1** (inicial)

### IAM Roles (IRSA)
- **Debezium Role**: Acesso a MSK e Secrets Manager (credenciais de DB)
- Service Account: `system:serviceaccount:debezium:debezium-connect`
- Permissões: kafka-cluster:*, secretsmanager:GetSecretValue

## 📁 Estrutura

```
.
├── provider.tf          # Terraform + AWS providers (multi-region)
├── variables.tf         # Variáveis (VPC IDs, MSK config)
├── data.tf             # Data sources (VPC, EKS)
├── peering.tf          # VPC Peering cross-region
├── main.tf             # MSK cluster e security groups
├── iam.tf              # IAM roles para Debezium (IRSA)
├── outputs.tf          # Outputs (MSK, IAM, Peering)
├── environments/
│   └── prod.tfvars     # Variáveis de produção
└── .github/
    └── workflows/      # CI/CD workflows
```

## 🚀 Deploy

### 1. Bootstrap (primeira vez)
```bash
# Criar bucket S3 para state e tabela DynamoDB para lock
aws s3api create-bucket \
  --bucket triphero-datalake-terraform-state-591698664739 \
  --region us-east-2 \
  --create-bucket-configuration LocationConstraint=us-east-2

aws s3api put-bucket-versioning \
  --bucket triphero-datalake-terraform-state-591698664739 \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name triphero-datalake-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-2
```

### 2. Terraform Init
```bash
terraform init
```

### 3. Terraform Plan
```bash
terraform plan -var-file=environments/prod.tfvars
```

### 4. Terraform Apply
```bash
terraform apply -var-file=environments/prod.tfvars
```

## 🔗 Conexão ao MSK

### Obter Bootstrap Brokers
```bash
aws kafka get-bootstrap-brokers \
  --cluster-arn <MSK_CLUSTER_ARN> \
  --region us-east-2
```

### Testar Conexão (kcat)
```bash
kcat -b <BOOTSTRAP_BROKERS> \
  -X security.protocol=SASL_SSL \
  -X sasl.mechanism=AWS_MSK_IAM \
  -X sasl.jaas.config="software.amazon.msk.auth.iam.IAMLoginModule required;" \
  -L
```

## 📊 Monitoramento

### CloudWatch Logs
```bash
aws logs tail /aws/msk/hero-trip-prod --follow --region us-east-2
```

### Métricas MSK
- Console AWS: MSK > Clusters > hero-trip-prod-msk > Monitoring

## 💰 Custos Estimados (Mensal)

| Recurso | Configuração | Custo Estimado |
|---------|-------------|----------------|
| VPC Peering | Cross-region (fixo) | $0 |
| MSK Cluster | 2x kafka.t3.small | ~$70 |
| MSK Storage | 200 GB EBS (2x 100GB) | ~$20 |
| Data Transfer | 500GB CDC ($0.02/GB) | ~$10 |
| CloudWatch Logs | MSK logs (7 dias) | ~$5 |
| **Total (Fase 1)** | | **~$105/mês** |
| | | |
| **Futuros** | | |
| + S3 Datalake | Standard | ~$23/TB/mês |
| + Redshift Serverless | On-demand | ~$300-500/mês |

## 🔧 Manutenção

### Atualizar Versão do Kafka
1. Alterar `kafka_version` em `environments/prod.tfvars`
2. Run `terraform plan` e verificar mudanças
3. Run `terraform apply` (MSK atualiza com zero downtime)

### Escalar Brokers
1. Alterar `msk_instance_type` (ex: kafka.t3.small → kafka.m5.large)
2. Alterar `msk_number_of_broker_nodes` (2 → 3 ou mais)
3. Ajustar `default.replication.factor` e `min.insync.replicas` na config
4. Apply mudanças (MSK escala sem downtime)

### Aumentar Storage
1. Alterar `msk_ebs_volume_size`
2. Apply mudanças (sem downtime)

## 📝 Versões

- **Terraform**: >= 1.9.0
- **AWS Provider**: ~> 5.75
- **Kafka (MSK)**: 3.9.0

## 🔐 Segurança

- ✅ Encryption at rest (EBS encrypted)
- ✅ Encryption in transit (TLS)
- ✅ IAM authentication (SASL/IAM)
- ✅ S3 bucket policy (block public access)
- ✅ Security Groups configurados
- ✅ VPC privada (private subnets)

## 📚 Referências

- [Amazon MSK Documentation](https://docs.aws.amazon.com/msk/)
- [Debezium Documentation](https://debezium.io/documentation/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
