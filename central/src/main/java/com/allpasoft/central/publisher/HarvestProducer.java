package com.allpasoft.central.publisher;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.allpasoft.central.entity.Harvest;
import org.springframework.amqp.core.AmqpTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class HarvestProducer {

    @Autowired
    private AmqpTemplate amqpTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    public void sendNuevaCosecha(Harvest harvest) {
        try {
            String message = objectMapper.writeValueAsString(harvest);
            amqpTemplate.convertAndSend("central.cosechas", message);
            System.out.println("[RabbitMQ] Evento nueva_cosecha enviado: " + message);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
