#!/bin/bash

# Скрипт для сборки Docker образа репликатора

IMAGE_NAME="mysql-ch-replicator"
IMAGE_TAG="latest"
REGISTRY=""  # Укажите ваш registry, например: registry.example.com/

# Сборка образа
echo "Сборка образа ${IMAGE_NAME}:${IMAGE_TAG}..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

if [ $? -eq 0 ]; then
    echo "Образ успешно собран!"
    
    # Если указан registry, тегируем и пушим
    if [ -n "$REGISTRY" ]; then
        FULL_IMAGE_NAME="${REGISTRY}${IMAGE_NAME}:${IMAGE_TAG}"
        echo "Тегирование образа как ${FULL_IMAGE_NAME}..."
        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE_NAME}
        
        echo "Загрузка образа в registry..."
        docker push ${FULL_IMAGE_NAME}
        
        if [ $? -eq 0 ]; then
            echo "Образ успешно загружен в registry!"
            echo "Используйте в values.yaml: image.repository=${REGISTRY}${IMAGE_NAME}"
        fi
    else
        echo "Для загрузки в registry укажите REGISTRY в скрипте"
    fi
else
    echo "Ошибка при сборке образа!"
    exit 1
fi

