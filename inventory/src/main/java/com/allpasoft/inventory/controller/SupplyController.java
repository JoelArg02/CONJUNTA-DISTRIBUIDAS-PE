package com.allpasoft.inventory.controller;

import com.allpasoft.inventory.entity.Supply;
import com.allpasoft.inventory.service.SupplyService;
import lombok.Getter;
import lombok.Setter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/supplies")
public class SupplyController {

    @Autowired
    private SupplyService supplyService;

    // DTO para crear insumo
    @Getter
    @Setter
    public static class CreateSupplyRequest {
        private String nombreInsumo;
        private double stock;
    }

    // DTO para ajustar stock
    @Getter
    @Setter
    public static class AdjustStockRequest {
        private String insumo;
        private double cantidad;
        private Long cosechaId;
    }

    // Crear nuevo insumo
    @PostMapping
    public Supply createSupply(@RequestBody CreateSupplyRequest request) {
        return supplyService.createSupply(request.getNombreInsumo(), request.getStock());
    }

    // Ajustar stock y publicar evento
    @PutMapping("/adjust")
    public String adjustStock(@RequestBody AdjustStockRequest request) {
        supplyService.adjustStock(request.getInsumo(), request.getCantidad(), request.getCosechaId());
        return "Stock ajustado y evento publicado";
    }
}
