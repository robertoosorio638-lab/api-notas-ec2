#!/bin/bash
dnf install -y nodejs
mkdir -p /opt/api
cat > /opt/api/server.js <<'FIN'
const http = require('http');

// Configuración (antes eran números y textos sueltos)
const PUERTO = 80;
const NOTA_MINIMA = 3.0;
const CODIGO_OK = 200;
const CODIGO_NO_ENCONTRADO = 404;

// Datos
const notasDelCurso = [4.5, 3.5, 2.5, 4.0];
const datosDelEquipo = {
  equipo: 'Trabajo individual',
  integrantes: ['Roberto Osorio'],
};

// Lógica (no sabe nada de HTTP)
function calcularPromedio(notas) {
  const suma = notas.reduce((acumulado, nota) => acumulado + nota, 0);
  return suma / notas.length;
}

function estaAprobado(promedio) {
  return promedio >= NOTA_MINIMA;
}

function armarResumenDeNotas(notas) {
  const promedio = calcularPromedio(notas);
  return { promedio, aprobado: estaAprobado(promedio) };
}

// Presentación: una sola función que escribe la respuesta
function responder(res, codigo, datos) {
  res.writeHead(codigo, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(datos, null, 2));
}

// Un manejador por ruta: cada uno hace una sola cosa
function manejarSalud(req, res) {
  responder(res, CODIGO_OK, { estado: 'ok' });
}

function manejarEquipo(req, res) {
  responder(res, CODIGO_OK, datosDelEquipo);
}

function manejarNotas(req, res) {
  responder(res, CODIGO_OK, armarResumenDeNotas(notasDelCurso));
}

function manejarRutaNoEncontrada(req, res) {
  responder(res, CODIGO_NO_ENCONTRADO, { error: 'Ruta no encontrada' });
}

const rutas = {
  '/salud': manejarSalud,
  '/equipo': manejarEquipo,
  '/notas': manejarNotas,
};

const servidor = http.createServer((req, res) => {
  const manejador = rutas[req.url] || manejarRutaNoEncontrada;
  manejador(req, res);
});

servidor.listen(PUERTO);
FIN
cat > /etc/systemd/system/api.service <<'FIN'
[Unit]
Description=API del equipo
After=network.target
[Service]
ExecStart=/usr/bin/node /opt/api/server.js
Restart=always
[Install]
WantedBy=multi-user.target
FIN
systemctl daemon-reload
systemctl enable --now api
