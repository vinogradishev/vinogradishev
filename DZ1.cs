using System.Globalization;
using System.Security.Cryptography.X509Certificates;

namespace DZ1
{
    internal class Program
    {
        public static void Main(string[] args)
        {
            int n = 0;                                                                //переменная для размерности таблицы
            int step = 0;                                                             //переменная для отметки о выполнении построения строк

            string TableSize;                                                         //строка для ввода размерности таблицы от пользователя
            string? TableUserText = "";                                               //строка для ввода слова от пользователя

            int HorizontalBorderLine = TableUserText.Length + 2 * n;                  //длинна горизонтальной границы

            do                                                                        //цикл опроса, который проверяет введённую размерность
            {
                Console.WriteLine("Введите размерность таблицы, от 1 до 6");
                TableSize = Console.ReadLine();
                if (TableSize == "" || TableSize == null)
                {
                    Console.WriteLine($"Вы ничего не ввели\n");
                    continue;
                }
                n = Int32.Parse(TableSize);
                if (n < 1 || n > 6)
                {
                    Console.WriteLine($"Неверно! Введите число 1 до 6, вы ввели: {n}\n");
                }
            } while (n < 1 || n > 6);
            do                                                                        //цикл опроса, который проверяет введённый текст
            {
                Console.WriteLine("Введите произвольный текст");
                TableUserText = Console.ReadLine();
                HorizontalBorderLine = TableUserText.Length + 2 * n;                  //длинна горизонтальной границы
                if (TableUserText == "" || TableUserText == null)
                {
                    Console.WriteLine($"Вы ничего не ввели\n");
                }
                else if (HorizontalBorderLine > 40) 
                {
                    Console.WriteLine($"К сожалению слово слишком длинное, ширина строки не должна превышать 40 единиц.\n");
                }
            } while (TableUserText == "" || HorizontalBorderLine > 40);

            string TableBorderHor = "";                                               //строка для формирования горизонтальной границы
            string TableBorderVer = "";                                               //строка для формирования вертикальной границы
            string TableWord = "";

            int VerticalBorderLine = 1 + 2 * (n - 1);                                 //длинна вертикальной границы

            for (int i = 0; i < HorizontalBorderLine; i++)                            //цикл, формирую строку для горизонтальной границы
            {
                TableBorderHor = TableBorderHor + "+";
            }

            for (int i = 0; i <= HorizontalBorderLine; i++)                           //цикл, формирует строку для вертикальной границы
            {
                if (i == 0 || i == HorizontalBorderLine - 1)
                {
                    TableBorderVer = TableBorderVer + "+";
                }
                else
                {
                    TableBorderVer = TableBorderVer + " ";
                }
            }

            for (int i = 0; i < TableUserText.Length + 2 * n; i++)                    //цикл, формирует строку с введённым словом
            {
                if (i == 0 || i == TableUserText.Length + 2 * n - 1)
                {
                    TableWord = TableWord + "+";
                }
                else if (i < n || (i >= n + TableUserText.Length && i < TableUserText.Length + 2 * n))
                {
                    TableWord = TableWord + " ";
                }
                else
                {
                    TableWord = TableWord + TableUserText[i - n];
                }

            }

            Console.WriteLine();

            while (step < 3)
            {
                switch (step)                                                          //цикл, в котором выбирается строка
                {
                    case 0 when TableWord != "":
                        step = FirstSQR(VerticalBorderLine, TableBorderHor, TableBorderVer, TableWord);
                        break;
                    case 1:
                        step += SecondSQR(VerticalBorderLine, HorizontalBorderLine, TableBorderHor);
                        break; 
                    case 2:
                        step += ThirdSQR(HorizontalBorderLine, TableBorderHor);
                        break;
                }
            }
        }
        public static int FirstSQR(int a, string HB, string VB, string VBT)             //функция для формирования первого блока
        {
            int i = a;
            Console.WriteLine(HB);
            while (i >= 0)
            {
                if (i == (a + 1) / 2)
                {
                    Console.WriteLine(VBT);
                }
                else if (i == 0) 
                {
                    break;
                }
                else
                {
                    Console.WriteLine(VB);
                }
                i--;
            }
            Console.WriteLine(HB);
            return 1;
        }
        public static int SecondSQR(int a, int b, string HB)                            //функция для формирования второго блока
        {
            for (int i = 0; i < a; i++)
            {
                if (i % 2 == 0)
                {
                    for (int j = 0; j < b; j++)
                    {
                        if (j == 0 || j == b - 1)
                        {
                            Console.Write("+");
                        }
                        else if (j % 2 == 1)
                        {
                            Console.Write(" ");
                        }
                        else
                        {
                            Console.Write("+");
                        }
                    }
                    Console.Write("\n");
                }
                else
                {
                    for (int j = 0; j < b; j++)
                    {
                        if (j == 0 || j == b - 1)
                        {
                            Console.Write("+");
                        }
                        else if (j % 2 == 1)
                        {
                            Console.Write("+");
                        }
                        else
                        {
                            Console.Write(" ");
                        }
                    }
                    Console.Write("\n");
                }
            }
            return 1;
        }
        public static int ThirdSQR(int a, string HB)                                   //функция для формирования третьего блока
        {
            Console.WriteLine(HB);
            for (int i = 0; i < a - 2; i++)
            {
                for (int j = 0; j < a; j++)
                {
                    if (j == 0 || j == a - 1)
                    {
                        Console.Write("+");
                    }
                    else if (i == j - 1 || i + j == a - 2)
                    {
                        Console.Write("+");
                    }
                    else
                    {
                        Console.Write(" ");
                    }
                }
                Console.Write("\n");
            }
            Console.WriteLine(HB);
            return 1;
        }
    }
}
