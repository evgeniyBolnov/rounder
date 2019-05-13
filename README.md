### Модуль для округления

| Параметр     | Описание                                    |
| ------------ | ------------------------------------------- |
| INPUT_WIDTH  | Входная разрядность шины                    |
| OUTPUT_WIDTH | Выходная разрядность шины                   |
| DEPTH        | Размер строки                               |
| COMPLEX      | Вид сигнала(действительный или комплексный) |

При комплексном сигнале (COMPLEX=1)  разрядность входных и выходных шин необходимо указывать в 2 раза больше. При обработки вход разбивается пополам (INPUT_WIDTH/2) и выравнивание высчитывается по всем данным, если необходимо выровнять отдельно реальную и мнимую части, проще использовать 2 данных модуля (COMPLEX=0)
