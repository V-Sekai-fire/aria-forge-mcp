#!/bin/bash

# Docker Compose helper script for bpy-mcp

set -e

PROJECT_NAME="bpy-mcp"

function show_help() {
    echo "Docker Compose helper script for $PROJECT_NAME"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  dev       Start development environment"
    echo "  prod      Start production environment"
    echo "  build     Build all services"
    echo "  stop      Stop all services"
    echo "  logs      Show logs"
    echo "  shell     Open shell in running container"
    echo "  clean     Remove containers and volumes"
    echo ""
    echo "Examples:"
    echo "  $0 dev          # Start development server"
    echo "  $0 prod         # Start production server"
    echo "  $0 build        # Build all images"
    echo "  $0 logs -f      # Follow logs"
    echo "  $0 shell        # Open shell in container"
}

function check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed or not in PATH"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo "Error: Docker Compose is not available"
        exit 1
    fi
}

function use_compose_v2() {
    if docker compose version &> /dev/null; then
        echo "docker compose"
    else
        echo "docker-compose"
    fi
}

function run_compose() {
    local compose_cmd=$(use_compose_v2)
    local compose_file="docker-compose.yml"

    # Use production compose file if specified
    if [ "$1" = "prod" ]; then
        compose_file="docker-compose.prod.yml"
        shift
    fi

    $compose_cmd -f $compose_file "$@"
}

case "${1:-help}" in
    "dev")
        check_docker
        echo "Starting development environment..."
        run_compose dev up --build
        ;;
    "prod")
        check_docker
        echo "Starting production environment..."
        run_compose prod up -d --build
        ;;
    "build")
        check_docker
        echo "Building services..."
        run_compose dev build
        ;;
    "stop")
        check_docker
        echo "Stopping services..."
        run_compose dev down
        ;;
    "logs")
        check_docker
        shift
        run_compose dev logs "$@"
        ;;
    "shell")
        check_docker
        echo "Opening shell in container..."
        run_compose dev exec bpy-mcp bash
        ;;
    "clean")
        check_docker
        echo "Cleaning up containers and volumes..."
        run_compose dev down -v --remove-orphans
        ;;
    "help"|*)
        show_help
        ;;
esac