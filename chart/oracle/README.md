# oracle

## Install

```sh
helm install <release> oci://ghcr.io/openhundun/charts/oracle --version 0.0.1
```

## Uninstall

```sh
helm uninstall <release>
kubectl -n <namespace> delete pvc data-<release>-0
```
