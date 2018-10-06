---
id: 2060
title: Cupid in inline assembly
date: 2017-11-27 18:30:15.000000000 +00:00
author: theme
layout: post
guid: https://xenotheme.wordpress.com/?p=2042
permalink_wp: "/?p=2060"
categories:
- Software
---

```
    #include <stdio.h>
    unsigned long id = 0, a = 0;
    int main() {
        printf("0x%08lx\n", id        );
        __asm__ (
            "movl %1, %%eax; \n\t" /\*  Cause cpuid instruction to return Maximum Return Value and the Vendor Identification String \*/
            "cpuid; \n\t"
            "movl %%eax, %0; \n\t"
            : "=g" (id)
            : "g" (a)
            : "%eax"
        );
        printf("0x%08lx\n", id        );
    }
```


The operand constraint is crucial to get the code compiled.  Replace them with “r” will generate error.