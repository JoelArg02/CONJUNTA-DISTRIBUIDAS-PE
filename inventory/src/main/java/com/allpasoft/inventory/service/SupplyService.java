package com.allpasoft.inventory.service;


import com.allpasoft.inventory.entity.Supply;
import com.allpasoft.inventory.repository.SupplyRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class SupplyService {

    @Autowired
    private SupplyRepository supplyRepository;

    public void adjustStock(String insumo, double cantidad) {
        Supply supply = supplyRepository.findAll()
                .stream()
                .filter(s -> s.getNombreInsumo().equalsIgnoreCase(insumo))
                .findFirst()
                .orElseThrow(() -> new RuntimeException("Insumo no encontrado"));

        supply.setStock(supply.getStock() - cantidad);
        supplyRepository.save(supply);

        System.out.println("RabbitMQ Event: inventario_ajustado -> { insumo: " +
                insumo + ", cantidad_reducida: " + cantidad + " }");
    }
}