FROM quay.io/centos/centos:stream8

ARG awscli_v=2.6.1
ARG awsvault_v=6.6.0
ARG docker_v=20.10.9
ARG terraform_v=1.1.9
ARG terraformdocs_v=0.16.0
ARG tflint_v=0.35.0
ARG yq_v=4.25.1

ADD ansible_collection_requirements.yml plugins.tf versions.tf ./

RUN dnf -y update && \
    dnf -y install glibc-langpack-en epel-release unzip curl bind-utils telnet bash-completion which sudo vim xz iputils && \
    dnf -y install ansible-core python3-boto3 python3-pyvmomi python3-requests dnf-utils git wget jq && \
    dnf clean all && rm -rf /var/cache/dnf/* && \
    pip3 install pre-commit mitogen

RUN curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${awscli_v}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install -i /usr/local/aws-cli -b /usr/local/bin &&\
    rm -rf awscliv2.zip

RUN curl -sL "https://github.com/99designs/aws-vault/releases/download/v${awsvault_v}/aws-vault-linux-amd64" -o "/usr/local/bin/aws-vault" && \
    chmod +x /usr/local/bin/aws-vault

RUN curl -sL "https://download.docker.com/linux/static/stable/x86_64/docker-${docker_v}.tgz" | \
    tar xvzf - -C /usr/local/bin --strip-components=1 docker/docker

RUN curl -s "https://releases.hashicorp.com/terraform/${terraform_v}/terraform_${terraform_v}_linux_amd64.zip" -o "terraform.zip" && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/terraform && \
    rm -rf terraform.zip

RUN curl -sL "https://github.com/segmentio/terraform-docs/releases/download/v${terraformdocs_v}/terraform-docs-v${terraformdocs_v}-linux-amd64" -o "/usr/local/bin/terraform-docs" && \
    chmod +x /usr/local/bin/terraform-docs

RUN curl -sL "https://github.com/terraform-linters/tflint/releases/download/v${tflint_v}/tflint_linux_amd64.zip" -o "tflint.zip" && \
    unzip tflint.zip && \
    mv tflint /usr/local/bin/tflint && \
    rm -rf tflint.zip

RUN curl -sL "https://github.com/mikefarah/yq/releases/download/v${yq_v}/yq_linux_amd64" -o "/usr/local/bin/yq" && \
    chmod +x /usr/local/bin/yq

RUN echo "export SHELL=/bin/bash" >> /root/.bashrc && \
    echo "export EDITOR=/usr/bin/vim" >> /root/.bashrc && \
    echo "alias ll='ls -l --color=auto'" >> /root/.bashrc && \
    yq shell-completion bash > /etc/bash_completion.d/yq && \
    echo "export AWS_ASSUME_ROLE_TTL=1h" >> /root/.bashrc && \
    echo "export AWS_SESSION_TTL=12h" >> /root/.bashrc && \
    ansible-galaxy collection install -r ansible_collection_requirements.yml && \
    terraform providers mirror ~/.terraform.d/plugins && \
    rm -rf ansible_collection_requirements.yml plugins.tf versions.tf

CMD ["/bin/bash"]
