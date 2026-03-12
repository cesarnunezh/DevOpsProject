# Local Persistent Storage Paths

These directories back the Postgres `hostPath` persistent volumes used by the Kubernetes overlays:

- `k8s/storage/dev/postgres`
- `k8s/storage/staging/postgres`
- `k8s/storage/prod/postgres`

The deployment scripts create these directories automatically before `kubectl apply -k`.

For Minikube with the Docker driver, these paths must exist on the host that runs the Kubernetes node.
