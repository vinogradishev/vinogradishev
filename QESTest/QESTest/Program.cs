using System;
using System.Text;
using System.Collections.Generic;
using System.Threading.Channels;
using System.Security.Cryptography.X509Certificates;
using System.Text.RegularExpressions;
using System.Linq.Expressions;

namespace Otus_Methods
{
    class SolvingTheQuadraticEquation
    {
        public static string[] _valueOfCoefficient = { "", "", "" };
        public static string[] _coefficients = { "a", "b", "c" };

        public static string _wrongAnswers = "";

        public static int _selectedValue = 0;

        public static IDictionary<string, string> _wrongTypeAnswers = new Dictionary<string, string>();

        public static void Main()
        {
            try
            {
                Menu.StartMenu();
            }
            catch (CalcDataException calcEx)
            {
                if (calcEx.severity == CalcDataException._Severity.Warning)
                {
                    FormatDataClass.FormatData(calcEx.Message, 0);
                }
                else if (calcEx.severity == CalcDataException._Severity.Error)
                {
                    FormatDataClass.FormatData(calcEx.Message, 1);
                }
                else if (calcEx.severity == CalcDataException._Severity.MissNumber)
                {
                    FormatDataClass.FormatData(calcEx.Message, -1);
                }
            }
        }

        public static bool IsNumeric(string input)
        {
            Regex regex = new Regex(@"^[0-9]+$");
            return regex.IsMatch(input);
        } 
    }
}