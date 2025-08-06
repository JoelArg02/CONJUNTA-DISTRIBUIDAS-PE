package com.allpasoft.inventory.listener;

import com.allpasoft.inventory.entity.Supply;
import com.allpasoft.inventory.repository.SupplyRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.amqp.core.AmqpTemplate;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

@Component
public class HarvestListener {

    @Autowired
    private SupplyRepository supplyRepository;

    @Autowired
    private AmqpTemplate amqpTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    private final String INVENTARIO_AJUSTADO_QUEUE = "inventario.ajustado";

    @RabbitListener(queues = "central.cosechas")
    public void consumeNuevaCosecha(String message) {
        try {
            JsonNode event = objectMapper.readTree(message);
            Long cosechaId = event.get("id").asLong();
            String producto = event.get("producto").asText();
            double toneladas = event.get("toneladas").asDouble();

            // Buscar insumo
            Supply supply = supplyRepository.findAll()
                    .stream()
                    .filter(s -> s.getNombreInsumo().equalsIgnoreCase(producto))
                    .findFirst()
                    .orElseThrow(() -> new RuntimeException("Insumo no encontrado: " + producto));

            // Actualizar stock
            supply.setStock(supply.getStock() - toneladas);
            supplyRepository.save(supply);

            // Publicar evento inventario_ajustado
            Map<String, Object> payload = new HashMap<>();
            payload.put("evento", "inventario_ajustado");
            payload.put("cosecha_id", cosechaId);
            payload.put("producto", producto);
            payload.put("toneladas", toneladas);
            payload.put("status", "OK");

            String payloadJson = objectMapper.writeValueAsString(payload);
            amqpTemplate.convertAndSend(INVENTARIO_AJUSTADO_QUEUE, payloadJson);
            System.out.println("[RabbitMQ] Evento inventario_ajustado enviado: " + payloadJson);

        } catch (Exception e) {
            e.printStackTrace();
            throw new RuntimeException("Error procesando mensaje de central.cosechas: " + e.getMessage());
        }
    }
}
