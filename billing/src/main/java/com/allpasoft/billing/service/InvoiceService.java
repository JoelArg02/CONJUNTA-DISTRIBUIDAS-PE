package com.allpasoft.billing.service;

import com.allpasoft.billing.entity.Invoice;
import com.allpasoft.billing.repository.InvoiceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@Service
public class InvoiceService {

    @Autowired
    private InvoiceRepository invoiceRepository;

    private static final Map<String, Double> PRECIOS = Map.of(
            "Arroz Oro", 120.0,
            "Café Premium", 300.0
    );

    public void generateInvoice(UUID cosechaId, String producto, double toneladas) {
        double precioBase = PRECIOS.getOrDefault(producto, 100.0);
        double monto = toneladas * precioBase;

        Invoice invoice = new Invoice();
        invoice.setCosechaId(cosechaId);
        invoice.setMonto(monto);
        invoice.setPagado(false);
        invoice.setCreadoEn(LocalDateTime.now());

        invoiceRepository.save(invoice);

        System.out.println("Notify Central API: PUT /cosechas/" + cosechaId +
                "/estado -> { estado: FACTURADA, factura_id: " + invoice.getId() + " }");
    }
}