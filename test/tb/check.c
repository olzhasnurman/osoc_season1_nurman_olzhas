 #include <stdio.h>
 #include <stdint.h>


int check(int8_t a0, int8_t mcause) {

    if ((mcause == 11) || (mcause == 3) ) {
        if ( a0 == 0 ) printf ("PASS\n");
        else if ( a0 == 1 ) printf ("FAIL\n");
        else printf ("UNDEFINED value stored in a0 register\n");
    }
    else if ( mcause == 2 ) printf("ILLEGAL INSTRUCTION\n");
    else if ( mcause == 0 ) printf("INSTRUCTION ADDR MA\n");
    else if ( mcause == 4 ) printf("LOAD ADDR MA\n");
    else if ( mcause == 6 ) printf("STORE ADDR MA\n");
    else printf ("UNDEFINED ERROR\n");

    return 0;

}
