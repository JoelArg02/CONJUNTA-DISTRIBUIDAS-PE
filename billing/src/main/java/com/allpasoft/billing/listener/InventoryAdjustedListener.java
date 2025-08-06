package com.allpasoft.billing.listener;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.allpasoft.billing.entity.Invoice;
import com.allpasoft.billing.service.InvoiceService;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class InventoryAdjustedListener {

    @Autowired
    private InvoiceService invoiceService;

    @Autowired
    private ObjectMapper objectMapper;

    @RabbitListener(queues = "inventario.ajustado")
    public void consumeInventarioAjustado(String message) {
        try {
            JsonNode event = objectMapper.readTree(message);

            Long cosechaId = event.get("cosecha_id").asLong();
            String producto = event.get("producto").asText();
            double toneladas = event.get("toneladas").asDouble();

            Invoice invoice = invoiceService.generarFactura(cosechaId, producto, toneladas);
            invoiceService.notificarCentral(cosechaId, invoice.getId());

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
