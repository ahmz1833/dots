FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Layer 1: Core system utilities, networking, and Python
RUN apt-get update -qq && \
    apt-get install -y -qq \
        sudo curl wget ca-certificates gnupg \
        build-essential tar zip unzip rsync less \
        iputils-ping dnsutils netcat-openbsd net-tools \
        iproute2 procps lsof openssh-client tcpdump \
        python3 python3-pip python3-venv python3-apt locales && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Layer 2: Interactive tools and environments
RUN apt-get update -qq && \
    apt-get install -y -qq \
        git zsh tmux vim nano htop tree ncdu jq ripgrep && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Layer 3: External binaries and system configurations
COPY setup-tools.sh /tmp/setup-tools.sh
RUN chmod +x /tmp/setup-tools.sh && \
    /tmp/setup-tools.sh && \
    rm -f /tmp/setup-tools.sh

CMD ["sleep", "infinity"]
