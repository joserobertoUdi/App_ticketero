namespace Ticketero.Domain.ValueObjects;

public record TimeTracking
{
    public int Segundos { get; init; }
    public int Minutos => Segundos / 60;
    public string Formateado => $"{Minutos:D2}:{Segundos % 60:D2}";

    public TimeTracking(int segundos)
    {
        Segundos = segundos;
    }

    public static TimeTracking Calcular(DateTime inicio, DateTime fin)
    {
        var segundos = (int)(fin - inicio).TotalSeconds;
        return new TimeTracking(Math.Max(0, segundos));
    }

    public static TimeTracking Zero => new(0);
}
