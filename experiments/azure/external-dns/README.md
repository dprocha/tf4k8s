# Terraform for configuring External DNS

Uses [k14s](https://github.com/k14s/terraform-provider-k14s) Terraform provider to configure [external-dns](https://github.com/kubernetes-sigs/external-dns).

Starts with the assumption that you have already provisioned an AKS cluster.

## Edit `terraform.tfvars`

Amend the values for

* `az_subscription_id`
* `az_client_id`
* `az_client_secret`
* `az_tenant_id`
* `resource_group_name`
* `domain_filter`
* `kubeconfig_path`


## Create

```
./create-external-dns.sh
```

## Teardown

```
./destroy-external-dns.sh
```
