#!/bin/sh
############################################################
# This script can install docker from docker binary files. #
# So first need the dir contains the docker bin files.     #
# You can compile the source code for binary files         #
# or get docker-ce binary from:                            #
# https://download.docker.com/linux/static/stable/x86_64/  #
############################################################


SYSTEMDDIR=/usr/lib/systemd/system
SERVICEFILE=docker.service
DOCKERDIR=/usr/bin
SERVICENAME=docker

precheck(){
  echo "Check the env before install docker..."
  if [ -f ${DOCKERDIR}/${SERVICENAME} ]; then
     echo "already had docker, remove current docker..."
     echo "Stop current ${SERVICENAME} service..."
     systemctl stop ${SERVICENAME}
     echo "Remove current ${SERVICENAME} bin files"
     rm -f ${DOCKERDIR}/${SERVICENAME}*
  fi
  echo "Finish precheck."
}


usage(){
  echo "Usage: $0 DOCKER_BIN_FILE_DIR"
  echo "       $0 ./docker/"
  echo "Get docker-ce binary from: https://download.docker.com/linux/static/stable/x86_64/ or compile source code yourself"
  echo "eg: wget https://download.docker.com/linux/static/stable/x86_64/docker-17.09.0-ce.tgz"
  echo ""
}


if [ $# -ne 1 ]; then
  usage
  exit 1
else
  DOCKERBIN="$1"
fi

precheck
if [ ! -d ${DOCKERBIN} ]; then
  echo "Docker binary dir does not exist, please check it"
  echo "Get docker-ce binary from: https://download.docker.com/linux/static/stable/x86_64/ or you can compile the docker source code for binary files"
  echo "eg: wget https://download.docker.com/linux/static/stable/x86_64/docker-17.09.0-ce.tgz"
  exit 1
fi

echo "##binary : ${DOCKERBIN} copy to ${DOCKERDIR}"
cp -p ${DOCKERBIN}/* ${DOCKERDIR} >/dev/null 2>&1
which ${SERVICENAME}

echo "##systemd service: ${SERVICEFILE}"
echo "##docker.service: create docker systemd file"
cat >${SYSTEMDDIR}/${SERVICEFILE} <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target docker.socket
[Service]
Type=notify
EnvironmentFile=-/run/flannel/docker
WorkingDirectory=/usr/local/bin
ExecStart=/usr/bin/dockerd \
                -H tcp://0.0.0.0:4243 \
                -H unix:///var/run/docker.sock \
                --selinux-enabled=false \
                --log-opt max-size=1g
ExecReload=/bin/kill -s HUP $MAINPID
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

echo ""

systemctl daemon-reload
echo "##Service status: ${SERVICENAME}"
systemctl status ${SERVICENAME}
echo "##Service restart: ${SERVICENAME}"
systemctl restart ${SERVICENAME}
echo "##Service status: ${SERVICENAME}"
systemctl status ${SERVICENAME}

echo "##Service enabled: ${SERVICENAME}"
systemctl enable ${SERVICENAME}

echo "## docker version"
docker version
