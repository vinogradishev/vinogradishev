using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Otus_Methods
{
    internal class Discriminant
    {
        public static void CalculateDiscriminant(string a_str, string b_str, string c_str)
        {
            int a;
            int b;
            int c;

            SolvingTheQuadraticEquation._wrongTypeAnswers.Clear();
            SolvingTheQuadraticEquation._wrongTypeAnswers.Add("a", a_str);
            SolvingTheQuadraticEquation._wrongTypeAnswers.Add("b", b_str);
            SolvingTheQuadraticEquation._wrongTypeAnswers.Add("c", c_str);

            if (!SolvingTheQuadraticEquation.IsNumeric(a_str))
                SolvingTheQuadraticEquation._wrongAnswers += "a, ";
            if (!SolvingTheQuadraticEquation.IsNumeric(b_str))
                SolvingTheQuadraticEquation._wrongAnswers += "b, ";
            if (!SolvingTheQuadraticEquation.IsNumeric(c_str))
                SolvingTheQuadraticEquation._wrongAnswers += "c, ";

            SolvingTheQuadraticEquation._wrongAnswers = SolvingTheQuadraticEquation._wrongAnswers.TrimEnd(',', ' ');

            try
            {
                a = int.Parse(a_str);
                b = int.Parse(b_str);
                c = int.Parse(c_str);
            }
            catch (OverflowException)
            {
                throw new CalcDataException("Задайте числа в диапазоне от -2 147 483 648 до 2 147 483 647", CalcDataException._Severity.MissNumber);
            }
            catch (FormatException)
            {
                throw new CalcDataException($"Неверный формат параметра(ов) {SolvingTheQuadraticEquation._wrongAnswers}", CalcDataException._Severity.Error);
            }
            catch
            {
                throw;
            }

            double x;
            double discriminant = (double)b * (double)b - 4 * (double)a * (double)c;

            if (discriminant < 0)
            {
                throw new CalcDataException("Вещественных значений не найдено.", CalcDataException._Severity.Warning);
            }
            else if (discriminant.CompareTo(0) == 0)
            {
                x = -(double)b / (2 * (double)a);

                Console.WriteLine($"x = {x}");
                Console.WriteLine("Для выхода нажмите любую клавишу");
                Console.ReadKey();
            }
            else
            {
                x = Math.Round((-(double)b + Math.Sqrt(discriminant)) / (2 * (double)a), 4);

                Console.Write($"x1 = {x}");
                Console.Write(", ");

                x = Math.Round((-(double)b - Math.Sqrt(discriminant)) / (2 * (double)a), 4);

                Console.Write($"x2 = {x}"); Console.WriteLine();
                Console.WriteLine("Для выхода нажмите любую клавишу");
                Console.ReadKey();
            }

        }
    }
}
