using System;

namespace FinanceHackathonAPI.DTOs
{
    // Kalemin türünü belirlemek için enum yapısı
    public enum FinancialItemType
    {
        Alacak,   // Müşterilerden gelecek para (Invoices / Receivables)
        Borc,     // Ödenmesi gereken fatura, kira, vergi (Payables)
        Gelir,    // Düzenli sabit gelirler (Maaş, ciro vb.)
        Gider     // Düzenli sabit giderler
    }

    public class FinancialItemDto
    {
        public string Title { get; set; } = string.Empty; // Örn: "X Şirketi Ürün Teslimatı Faturası", "Dükkan Kirası"
        public decimal Amount { get; set; } // Tutar
        public FinancialItemType ItemType { get; set; } // Alacak mı, Borç mu?
        public DateTime DueDate { get; set; } // Son ödeme / tahsilat tarihi
        public bool IsPaid { get; set; } // Ödendi mi? (True ise analizde kritik alarm oluşturmaz)
    }
}