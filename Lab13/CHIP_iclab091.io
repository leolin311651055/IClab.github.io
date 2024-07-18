###############################################################
#  Generated by:      Cadence Innovus 20.15-s105_1
#  OS:                Linux x86_64(Host ID ee21)
#  Generated on:      Mon Jul 31 20:58:48 2023
#  Design:            CHIP
#  Command:           saveIoFile -byOrder CHIP.io
###############################################################

(globals
    version = 3
	space = 31
    io_order = default
)
(iopad
    (top
		(inst  name="VDDP1"	place_status=placed )
    (inst  name="I_RST"	place_status=placed )
    (inst  name="I_CLK" place_status=placed )
		(inst  name="GNDP1"	place_status=placed )
		(endspace gap=31)
    )
    (right
		(inst  name="VDDP0"	place_status=placed )
    (inst  name="O_VALID" place_status=placed )
    (inst  name="O_CODE" place_status=placed )
		(inst  name="GNDP0"	place_status=placed )
		(endspace gap=31)
    )
    (bottom
		(inst  name="VDDC0"	place_status=placed )
    (inst  name="GNDC0"	place_status=placed )
    (inst  name="I_IN_VALID" place_status=placed )
    (inst  name="I_OUT_MODE" place_status=placed )
		(endspace gap=31)
    )
    (left
		(inst  name="VDDC1"	place_status=placed )
    (inst  name="I_WEIGHT_IDX0" place_status=placed )
    (inst  name="I_WEIGHT_IDX1" place_status=placed )
    (inst  name="I_WEIGHT_IDX2" place_status=placed )
		(inst  name="GNDC1"	place_status=placed )
		(endspace gap=31)
    )
	(topright
        (inst  name="topright"  cell="CORNERD" )
    )
        (topleft
        (inst  name="topleft"   cell="CORNERD" )
    )
        (bottomright
        (inst  name="bottomright"       cell="CORNERD" )
    )
        (bottomleft
        (inst  name="bottomleft"        cell="CORNERD" )
    )

)