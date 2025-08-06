package com.allpasoft.billing.service;

import com.allpasoft.billing.entity.Invoice;
import com.allpasoft.billing.repository.InvoiceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.Map;

@Service
public class InvoiceService {

    @Autowired
    private InvoiceRepository invoiceRepository;

    private static final Map<String, Double> PRECIOS = Map.of(
            "Arroz Oro", 120.0,
            "Café Premium", 300.0
    );

    public Invoice generarFactura(Long cosechaId, String producto, double toneladas) {
        double precioBase = PRECIOS.getOrDefault(producto, 100.0);
        double monto = toneladas * precioBase;

        Invoice invoice = new Invoice();
        invoice.setCosechaId(cosechaId);
        invoice.setMonto(monto);
        invoice.setPagado(false);
        invoice.setCreadoEn(LocalDateTime.now());

        invoiceRepository.save(invoice);
        return invoice;
    }

    public void notificarCentral(Long cosechaId, Long facturaId) {
        RestTemplate restTemplate = new RestTemplate();
        String url = "http://localhost:8000/cosechas/" + cosechaId + "/estado";
        Map<String, String> body = Map.of(
                "estado", "FACTURADA",
                "factura_id", facturaId.toString()
        );
        restTemplate.put(url, body);
        System.out.println("[HTTP] Notificación enviada a Central: " + body);
    }
}
