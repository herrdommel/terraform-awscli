FROM debian:12-slim AS installer

ARG TERRAFORM_VERSION=1.13.5
ARG TERRAFORM_OS=linux
ARG TERRAFORM_ARCH=amd64
ARG AWS_CLI_VERSION=2.31.33

COPY aws_public_key.asc .

# Install dependencies and tools
RUN apt-get update && apt-get install -y curl gnupg unzip ca-certificates \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-$(arch)-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-$(arch)-${AWS_CLI_VERSION}.zip.sig" -o "awscliv2.sig" \
    && gpg --import aws_public_key.asc \
    && gpg --verify awscliv2.sig awscliv2.zip \
    && unzip awscliv2.zip \
    # The --bin-dir is specified so that we can copy the
    # entire bin directory from the installer stage into
    # into /usr/local/bin of the final stage without
    # accidentally copying over any other executables that
    # may be present in /usr/local/bin of the installer stage.
    && ./aws/install --bin-dir /aws-cli-bin/ \
    && curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${TERRAFORM_OS}_${TERRAFORM_ARCH}.zip" -o terraform.zip \
    && unzip terraform.zip -d /terraform-cli-bin

FROM debian:12-slim

COPY --from=installer /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /aws-cli-bin/ /usr/local/bin/
COPY --from=installer /terraform-cli-bin/terraform /usr/local/bin/
COPY --from=installer /terraform-cli-bin/LICENSE.txt /usr/share/doc/terraform/

ENTRYPOINT ["/usr/local/bin/terraform"]

