#! /bin/bash

set -e

name=$1
repo=$2
dependency=$name
search=$(helm search repo $name | tail -n 1)
version=$(echo $search | sed "s:.*/$name[[:space:]]*\([0-9]*\.[0-9]*\.[0.9]*\).*:\1:g")
reponame=$(echo $search | sed "s:\(.*\)/$name.*:\1:g")


mkdir $name

cat > $name/Chart.yaml <<EOL
apiVersion: v2
name: $name
version: "0.0.1"
dependencies: 
  - name: $dependency
    version: $version
    repository: $repo
... 
EOL

cat > projects/$name.yaml <<EOL
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: $name
  namespace: argocd
spec:
  sourceRepos:
  - https://github.com/KSmigielski/truenas-k8s

  destinations:
  - namespace: $name
    server: https://kubernetes.default.svc

  clusterResourceWhitelist:
  - group: '*'
    kind: "*"

  namespaceResourceWhitelist:
  - group: '*'
    kind: "*"
EOL

cat > apps/$name.yaml <<EOL
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $name
  namespace: argocd
spec:
  project: $name

  source:
    repoURL: https://github.com/KSmigielski/truenas-k8s
    targetRevision: HEAD
    path: $name
  destination:
    server: https://kubernetes.default.svc
    namespace: $name

  syncPolicy:
    automated: 
      prune: true 
      selfHeal: true 
      allowEmpty: false 
    syncOptions:
    - CreateNamespace=true 
EOL


helm dependency update $name --skip-refresh
echo "$name:" > $name/values.yaml
helm show values $reponame/$name | sed 's/^/  /g' >> $name/values.yaml
