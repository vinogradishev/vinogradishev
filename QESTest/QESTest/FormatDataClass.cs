using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Otus_Methods
{
    internal class FormatDataClass
    {
        public static void FormatData(string message, int severity)
        {
            if (severity == 0)
            {
                Console.ForegroundColor = ConsoleColor.Black;
                Console.BackgroundColor = ConsoleColor.Yellow;
                Console.WriteLine(string.Join("", Enumerable.Repeat("-", 50)));
                Console.WriteLine(message);
                Console.WriteLine(string.Join("", Enumerable.Repeat("-", 50)));
                Console.ResetColor();
                Console.WriteLine("Для выхода нажмите любую клавишу");
                Console.ReadKey();
            }
            else if (severity == 1)
            {
                Console.ForegroundColor = ConsoleColor.White;
                Console.BackgroundColor = ConsoleColor.Red;
                Console.WriteLine(string.Join("", Enumerable.Repeat("-", 50)));
                Console.WriteLine(message);
                Console.WriteLine(string.Join("", Enumerable.Repeat("-", 50)));
                Console.WriteLine(string.Join("", Enumerable.Repeat(" ", 50)));
                foreach (KeyValuePair<string, string> kvp in SolvingTheQuadraticEquation._wrongTypeAnswers)
                {
                    Console.WriteLine($"{kvp.Key} = {kvp.Value}");
                }
                Console.ResetColor();
                Console.WriteLine("Для повторного ввода нажмите любую клавишу");
                Console.ReadKey();
                Array.Clear(SolvingTheQuadraticEquation._valueOfCoefficient, 0, SolvingTheQuadraticEquation._valueOfCoefficient.Length);
                SolvingTheQuadraticEquation._wrongAnswers = string.Empty;
                Console.Clear();
                SolvingTheQuadraticEquation.Main();
            }
            else if (severity == -1)
            {
                Console.ForegroundColor = ConsoleColor.White;
                Console.BackgroundColor = ConsoleColor.Green;
                Console.WriteLine(string.Join("", Enumerable.Repeat("-", 60)));
                Console.WriteLine(message);
                Console.WriteLine(string.Join("", Enumerable.Repeat("-", 60)));
                Console.ResetColor();
                Console.WriteLine("Для повторного ввода нажмите любую клавишу");
                Console.ReadKey();

                SolvingTheQuadraticEquation._valueOfCoefficient[0] = "";
                SolvingTheQuadraticEquation._valueOfCoefficient[1] = "";
                SolvingTheQuadraticEquation._valueOfCoefficient[2] = "";

                Console.Clear();
                SolvingTheQuadraticEquation.Main();
            }
        }
    }
}
