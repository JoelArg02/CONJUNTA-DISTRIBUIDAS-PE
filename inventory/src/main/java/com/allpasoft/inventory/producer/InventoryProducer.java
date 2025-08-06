package com.allpasoft.inventory.producer;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.amqp.core.AmqpTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class InventoryProducer {

    @Autowired
    private AmqpTemplate amqpTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    public void sendInventarioAjustado(Map<String, Object> payload) {
        try {
            String message = objectMapper.writeValueAsString(payload);
            amqpTemplate.convertAndSend("inventario.ajustado", message);
            System.out.println("[RabbitMQ] Evento inventario_ajustado enviado: " + message);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
