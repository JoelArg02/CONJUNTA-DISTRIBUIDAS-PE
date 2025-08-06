package com.allpasoft.inventory.service;

import com.allpasoft.inventory.entity.Supply;
import com.allpasoft.inventory.repository.SupplyRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.amqp.core.AmqpTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class SupplyService {

    @Autowired
    private SupplyRepository supplyRepository;

    @Autowired
    private AmqpTemplate amqpTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    private final String INVENTARIO_AJUSTADO_QUEUE = "inventario.ajustado";

    // Crear un nuevo insumo
    public Supply createSupply(String nombreInsumo, double stock) {
        Supply supply = new Supply();
        supply.setNombreInsumo(nombreInsumo);
        supply.setStock(stock);
        return supplyRepository.save(supply);
    }

    // Ajustar stock y publicar evento
    public void adjustStock(String insumo, double cantidad, Long cosechaId) {
        Supply supply = supplyRepository.findAll()
                .stream()
                .filter(s -> s.getNombreInsumo().equalsIgnoreCase(insumo))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Insumo no encontrado"));

        // Ajuste del stock
        supply.setStock(supply.getStock() - cantidad);
        supplyRepository.save(supply);

        // Construir payload del evento
        Map<String, Object> payload = new HashMap<>();
        payload.put("evento", "inventario_ajustado");
        payload.put("cosecha_id", cosechaId.toString());
        payload.put("insumo", insumo);
        payload.put("cantidad_reducida", cantidad);
        payload.put("status", "OK");

        try {
            String message = objectMapper.writeValueAsString(payload);
            amqpTemplate.convertAndSend(INVENTARIO_AJUSTADO_QUEUE, message);
            System.out.println("[RabbitMQ] Evento inventario_ajustado enviado: " + message);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
