#!/bin/bash

# Detectar si usar docker-compose o docker compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo "Error: No se encontró ni docker-compose ni docker compose."
    exit 1
fi

# Obtener la IP del servidor
SERVER_IP=$(ip -4 addr show | grep -oP '(?<=inet\s)192\.168\.\d+\.\d+')

if [ -z "$SERVER_IP" ]; then
    echo "No se pudo detectar la IP del servidor."
    exit 1
fi

echo -e "\n\033[1;32mLa IP del servidor es:\033[0m $SERVER_IP"

# Eliminar y regenerar nginx.conf
if [ -f nginx.conf ]; then
    echo "Eliminando el archivo nginx.conf existente..."
    rm nginx.conf
fi

cat <<EOF > nginx.conf
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name _;

        # Root directory for serving the HTML page
        root /usr/share/nginx/html;
        index index.html;

        # Proxy to Jenkins
        location /jenkins {
            proxy_pass http://$SERVER_IP:8080;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Proxy to Zabbix
        location /zabbix {
            proxy_pass http://$SERVER_IP:8084;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Proxy to Portainer
        location /portainer {
            proxy_pass http://$SERVER_IP:9000;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Serve images from the img directory
        location /img/ {
            root /usr/share/nginx/html;
        }
    }
}
EOF
echo -e "\033[1;34mEl archivo nginx.conf ha sido generado con la IP $SERVER_IP.\033[0m"

# Eliminar y regenerar index.html
if [ -f index.html ]; then
    echo "Eliminando el archivo index.html existente..."
    rm index.html
fi

cat <<EOF > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SOWIN - Panel de Servicios</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            background-color: #f4f4f4;
            color: #333;
        }
        header {
            display: flex;
            align-items: center;
            background-color: #c62828;
            color: white;
            padding: 15px 20px;
        }
        header .logo {
            width: 50px;
            height: 50px;
            background: white;
            border-radius: 50%;
            margin-right: 15px;
        }
        header h1 {
            font-size: 1.5em;
            margin: 0;
        }
        header nav {
            margin-left: auto;
        }
        header nav a {
            color: white;
            margin-left: 15px;
            text-decoration: none;
            font-weight: bold;
        }
        header nav a:hover {
            text-decoration: underline;
        }
        .container {
            max-width: 1200px;
            margin: 20px auto;
            padding: 20px;
            text-align: center;
        }
        .card {
            display: inline-block;
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            margin: 20px;
            text-align: left;
            width: 300px;
            transition: transform 0.3s;
        }
        .card:hover {
            transform: scale(1.05);
            box-shadow: 0 6px 10px rgba(0, 0, 0, 0.15);
        }
        .card img {
            max-width: 100%;
            height: 100px;
            transition: transform 0.3s;
        }
        .card img:hover {
            transform: scale(1.2);
        }
        .card h3 {
            color: #c62828;
            font-size: 1.5em;
        }
        .card p {
            color: #666;
        }
        .card a {
            display: inline-block;
            background: #c62828;
            color: white;
            padding: 10px 20px;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 10px;
        }
        .card a:hover {
            background: #e53935;
        }
    </style>
</head>
<body>
<header>
    <div class="logo"></div>
    <h1>SOWIN - Panel de Servicios</h1>
    <nav>
        <a href="https://aws.amazon.com/es/">AWS</a>
        <a href="https://github.com/andresdocker/ARCHIVO_DOCKER">GitHub</a>
        <a href="https://hub.docker.com">Docker</a>
        <a href="https://registry.terraform.io/browse/providers">Terraform</a>
    </nav>
</header>
<div class="container">
    <div class="card">
        <img src="/img/jenkins.png" alt="Jenkins Logo">
        <h3>Jenkins</h3>
        <p>Automatiza tus pipelines de CI/CD.</p>
        <a href="http://$SERVER_IP:8080">Ir a Jenkins</a>
    </div>
    <div class="card">
        <img src="/img/portainer.png" alt="Portainer Logo">
        <h3>Portainer</h3>
        <p>Gestiona tus contenedores y Docker desde una interfaz.</p>
        <a href="http://$SERVER_IP:9000">Ir a Portainer</a>
    </div>
    <div class="card">
        <img src="/img/zabbix.png" alt="Zabbix Logo">
        <h3>Zabbix</h3>
        <p>Monitoreo de infraestructura y sistemas.</p>
        <a href="http://$SERVER_IP:8084">Ir a Zabbix</a>
    </div>
</div>
</body>
</html>
EOF
echo -e "\033[1;34mEl archivo index.html ha sido generado con la IP $SERVER_IP.\033[0m"

# Reiniciar automáticamente los contenedores
echo -e "\033[1;33mReiniciando los contenedores...\033[0m"
$DOCKER_COMPOSE down
$DOCKER_COMPOSE up -d
echo -e "\033[1;32mLos contenedores han sido reiniciados.\033[0m"

# Obtener contraseña inicial de Jenkins
JENKINS_CONTAINER="dockerandres-jenkins"
JENKINS_PASSWORD=""
TIMEOUT=120
START_TIME=$(date +%s)

echo -e "\033[1;33mEsperando a que el contenedor de Jenkins esté listo...\033[0m"
while [ -z "$JENKINS_PASSWORD" ]; do
    if docker exec "$JENKINS_CONTAINER" test -f /var/jenkins_home/secrets/initialAdminPassword &>/dev/null; then
        JENKINS_PASSWORD=$(docker exec "$JENKINS_CONTAINER" cat /var/jenkins_home/secrets/initialAdminPassword)
    fi
    CURRENT_TIME=$(date +%s)
    if [ $((CURRENT_TIME - START_TIME)) -ge $TIMEOUT ]; then
        echo -e "\033[1;31mError: Tiempo de espera agotado para obtener la contraseña inicial de Jenkins.\033[0m"
        exit 1
    fi
    sleep 2
done

# Mostrar resultados
echo -e "\n\033[1;35m==================== Herramientas ====================\033[0m"
echo -e "\033[1;36mJenkins:   \033[0mhttp://$SERVER_IP:8080"
echo -e "\033[1;36mZabbix:    \033[0mhttp://$SERVER_IP:8084"
echo -e "\033[1;36mPortainer: \033[0mhttp://$SERVER_IP:9000"
echo -e "\033[1;35m=====================================================\033[0m"

echo -e "\n\033[1;33mContraseña inicial de Jenkins:\033[0m $JENKINS_PASSWORD"

# Añadir ASCII Art
echo -e "\033[30m@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@\033[37m..,.\033[30m@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@\033[37m......,\033[30m#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@\033[37m....,/(.\033[30m@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@\033[37m....../(..@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@\033[37m.../.,,,,...@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@\033[33m/%......,#(,,,,..\033[37m,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@\033[33m..../(((/(((/,,,,,,,,.*\033[30m.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@\033[37m./* .(((*/.,,,,..,...,,...\033[30m@(@@@@@@@@@@@@@@@@...@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@\033[37m...*..,..,,....,/.......,.....*....*....@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@\033[37m........../....,,,,,.....,....,........@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@\033[37m...........,.,,..,,.........,.........*..@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@\033[37m.........,,,,,..,,.......................@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@\033[37m....,/(.,..,,,,,,.........................@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@\033[37m/..///(....,,,.......,....................@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@....................@@@@@....,............&@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@..........,,...@@@@@@@@@@@@.........,.......@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@..........,,.,/@@@@@@@@@@@@@@......*.........@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@\033[33m......@...,../@@@@@@@@@@@@@@@@@*/**,..........@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@\033[33m......@@.....%@@@@@@@@@@@@@@@@@@@/***/.@@#*///..@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@\033[33m......@@..,..(@@@@@@@@@@@@@@@@@@@@/////@@@@@///.@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@\033[33m/..//@@@..,.@@@@@@@@@@@@@@@@@@@@@@(///*@@@@@////@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@\033[33m//((/@@@///(@@@@@@@@@@@@@@@@@@@@@@/*///@@@@@////@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@//(//@@@//((@@@@@@@@@@@@@@@@@@@@///////&@@@/**//@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@//((/%@#/(((*(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\033[0m"

