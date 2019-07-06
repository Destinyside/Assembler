SECTIONS {
	    ENTRY(start_head)
	        .text 0x0000 : {
			        *(.text)
				    }

				        .rodata . : {
						        *(.rodata)
							    }

							        .data . : {
									        *(.data)
										    }

										        /DISCARD/ : {
												        *(.eh_frame)
													    }
												    }
