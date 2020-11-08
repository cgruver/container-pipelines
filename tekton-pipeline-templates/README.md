# Tekton Pipelines for Java Applications

## Quarkus JVM

## Quarkus Fast-JAR

## Quarkus Native

## Spring Boot

This project provides an opinionated set of pipelines that allow development teams to set up CI/CD for their projects without maintaining pipeline boilerplate within their development code base.

The capabilities provided are achieved by taking advantage of OpenShift Templates exposed through the Catalog, and the Namespace Configuration Operator which synchronizes and maintains common artifacts across labeled namespaces.

Create a maven group in Nexus: homelab-central

Expose the Internal Registry:

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
podman login -u $(oc whoami) -p $(oc whoami -t) --tls-verify=false $(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')

```

Tekton:

Install Tekton Operator:

```bash
git clone https://github.com/cgruver/tekton-pipeline-okd4.git
cd tekton-pipeline-okd4
oc apply -f ./operator/operator_v1alpha1_config_crd.yaml
oc apply -f ./operator/role.yaml -n openshift-operators
oc apply -f ./operator/role_binding.yaml -n openshift-operators
oc apply -f ./operator/service_account.yaml -n openshift-operators
oc apply -f ./operator/operator.yaml -n openshift-operators
oc apply -f ./operator/operator_v1alpha1_config_cr.yaml
```

Create pipeline images and push to the internal OKD registry:

```bash
IMAGE_REGISTRY=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
podman login -u $(oc whoami) -p $(oc whoami -t) --tls-verify=false ${IMAGE_REGISTRY}

podman pull quay.io/openshift/origin-cli:4.5.0
podman tag quay.io/openshift/origin-cli:4.5.0 ${IMAGE_REGISTRY}/openshift/origin-cli:4.5.0
podman push ${IMAGE_REGISTRY}/openshift/origin-cli:4.5.0 --tls-verify=false


podman build -t ${IMAGE_REGISTRY}/openshift/jdk-ubi-minimal:8.1 jdk-ubi-minimal/
podman push ${IMAGE_REGISTRY}/openshift/jdk-ubi-minimal:8.1 --tls-verify=false

podman build -t ${IMAGE_REGISTRY}/openshift/maven-ubi-minimal:3.6.3-jdk-11 maven-ubi-minimal/
podman push ${IMAGE_REGISTRY}/openshift/maven-ubi-minimal:3.6.3-jdk-11 --tls-verify=false

podman build -t ${IMAGE_REGISTRY}/openshift/buildah:noroot buildah-noroot/
podman push ${IMAGE_REGISTRY}/openshift/buildah:noroot --tls-verify=false
```

Install Namespace Configuration Operator:

```bash
git clone https://github.com/redhat-cop/namespace-configuration-operator.git
cd namespace-configuration-operator
oc adm new-project namespace-configuration-operator
oc apply -f deploy/olm-deploy -n namespace-configuration-operator
```

Generate a GitHub Personal Access Token

Create a Secret for your git repo:

```yaml
apiVersion: v1
kind: Secret
metadata:
    name: git-secret
    annotations:
    tekton.dev/git-0: github.com
type: kubernetes.io/ssh-auth
data:
    token: <GitHub Access Token>
    secret: <A-Pass-Phrase-For-The-Repo-Web-Hook-Secret>
```

Or, use SSH access:

```bash
ssh-keygen -t rsa -f ~/.ssh/git.id_rsa -N ''

GIT_HOST=github.com
SSH_KEY=$(cat ~/.ssh/git.id_rsa | base64 -w0 )
KNOWN_HOSTS=$(ssh-keyscan ${GIT_HOST} | base64 -w0 )
cat << EOF > git-secret.yml
apiVersion: v1
kind: Secret
metadata:
    name: git-secret
    annotations:
      tekton.dev/git-0: ${GIT_HOST}
type: kubernetes.io/ssh-auth
data:
    ssh-privatekey: ${SSH_KEY}
    known_hosts: ${KNOWN_HOSTS}
EOF

oc apply -f git-secret.yml
rm -f git-secret.yml
oc patch sa pipeline --type merge --patch '{"secrets":[{"name":"git-secret"}]}'
oc adm policy add-scc-to-user nonroot -z pipeline
```

Create templates:

```bash
oc apply -f quarkus-jvm-pipeline-template.yml -n openshift
```

Deploy Pipeline objects:

```bash
oc process --local -f namespace-configuration.yml -p MVN_MIRROR_ID=homelab-central -p MVN_MIRROR_NAME=homelab-central -p MVN_MIRROR_URL=https://nexus.your.domain.com:8443/repository/homelab-central/ | oc apply -f -
```

Label your namespace:

```bash
oc label namespace my-namespace pipeline=tekton
```

Deploy an Application:

```bash
oc process openshift//quarkus-jvm-pipeline-dev -p APP_NAME=your-project-name -p GIT_REPOSITORY=git@bitbucket.org:your/project.git -p GIT_BRANCH=master | oc create -f -
```
