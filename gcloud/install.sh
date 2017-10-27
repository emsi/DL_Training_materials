#!/bin/bash
echo "Checking for CUDA and installing."

# Instaling docker
apt-get update && apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce


# Configure training environment
docker run -d -p 80:80 -p 443:443 --name nginx -v /rev-proxy/htpasswd:/etc/nginx/htpasswd -v /etc/nginx/conf.d -v /etc/nginx/vhost.d -v /usr/share/nginx/html -v /rev-proxy/certs/:/etc/nginx/certs:ro --label com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy=true nginx

docker run -d --name nginx-gen --volumes-from nginx -v /rev-proxy/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/docker-gen -notify-sighup nginx -watch -wait 5s:30s /etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf

docker run -d --name nginx-letsencrypt -e "NGINX_DOCKER_GEN_CONTAINER=nginx-gen" --volumes-from nginx -v /rev-proxy/certs/:/etc/nginx/certs:rw -v /var/run/docker.sock:/var/run/docker.sock:ro jrcs/letsencrypt-nginx-proxy-companion

# Check for CUDA and try to install.
cd /root
if ! dpkg-query -W cuda-8-0; then
curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
dpkg -i ./cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
apt-get update
apt-get install cuda-8-0 -y
fi

# Install nvidia-docker
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb
git clone https://github.com/emsi/DL_Training_materials
cd DL_Training_materials
./Docker/docker-build


# Build emsi/dl_training docker
mkdir /rev-proxy
mkdir /rev-proxy/htpasswd
mkdir /rev-proxy/certs
cp ./Docker/nginx.tmpl /rev-proxy/nginx.tmpl

# emsi/dl_training docker
docker pull xmartlabs/htpasswd
docker run --rm -ti xmartlabs/htpasswd -m dl qpqp01 > /rev-proxy/htpasswd/dl-goole.qpqp01.pl
NV_GPU=0 nvidia-docker run -d --name dl-google -h d-google -e "VIRTUAL_HOST=dl-google.ltcpln.pl" -e "LETSENCRYPT_HOST=dl-google.ltcpln.pl" -e "LETSENCRYPT_EMAIL=emsi@qpqp01.pl" -e "VIRTUAL_PORT=8888" emsi/dl_training

cat >> /root/env-up << EOF
# env-up script
for i in \$(seq 1 7); do
	echo \$i
	docker run --rm -ti xmartlabs/htpasswd -m dl qpqp01 > /rev-proxy/htpasswd/dl\$i.qpqp01.pl
	NV_GPU=\$i nvidia-docker run -d --name dl\$i -h dl\$i -e "VIRTUAL_HOST=dl\$i.ltcpln.pl" -e "LETSENCRYPT_HOST=dl\$i.ltcpln.pl" -e "LETSENCRYPT_EMAIL=emsi@qpqp01.pl" -e "VIRTUAL_PORT=8888" emsi/dl_training
done
EOF
chmod +x /root/env-up


