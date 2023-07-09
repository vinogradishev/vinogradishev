using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static Otus_Methods.SolvingTheQuadraticEquation;

namespace Otus_Methods
{
    internal class CalcDataException : Exception
    {
        public enum _Severity
        {
            Warning,
            Error,
            MissNumber
        }

        public _Severity severity { get; }
        public CalcDataException(string message, _Severity severity) : base(message)
        {
            this.severity = severity;
        }
    }
}
