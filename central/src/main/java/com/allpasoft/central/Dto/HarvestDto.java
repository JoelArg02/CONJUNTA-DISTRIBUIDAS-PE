package com.allpasoft.central.Dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class HarvestDto {
    private Long farmerId;
    private String producto;
    private Double toneladas;
}

