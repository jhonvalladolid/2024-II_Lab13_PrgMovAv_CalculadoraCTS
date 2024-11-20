//
//  CTSCalculator.swift
//  CTSCalculatorApp
//
//  Created by Mac5 on 20/11/24.
//

import SwiftUI
import PDFKit

/// Enum para los temas de la aplicación
enum Theme: String, CaseIterable, Identifiable {
    case light = "Claro"
    case dark = "Oscuro"
    case auto = "Automático"
     
    var id: String { self.rawValue }
}

struct CTSCalculatorView: View {
    @State private var fechaIngreso = Date()
    @State private var periodoInicial = Date()
    @State private var sueldoBruto: String = ""
    @State private var gratificacion: String = ""
    @State private var asignacionFamiliar: Bool = false
    @State private var mesesComputables: Int = 0
    @State private var diasComputables: Int = 0
    @State private var totalRemuneracionComputable: Double = 0.0
    @State private var ctsTotal: Double = 0.0
    @State private var mostrarSelectorTema = false
    @State private var mostrarOpciones = false

    @AppStorage("selectedTheme") private var selectedTheme: Theme = .auto

    var periodoFinal: Date {
        Calendar.current.date(byAdding: .month, value: 5, to: periodoInicial)?.endOfMonth ?? periodoInicial
    }

    var gratificacionOrdinaria: Double {
        guard let gratificacionValue = Double(gratificacion) else { return 0.0 }
        return gratificacionValue / 6.0
    }

    var body: some View {
        NavigationView {
            ZStack {
                fondoSegunTema(selectedTheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Calculadora de CTS")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(colorTextoSegunTema(selectedTheme))
                            .multilineTextAlignment(.center)

                        // Fecha de ingreso
                        DatePicker("Fecha de Ingreso", selection: $fechaIngreso, displayedComponents: .date)
                            .padding(.horizontal)
                            .background(colorCampoSegunTema(selectedTheme))
                            .cornerRadius(8)

                        // Periodo inicial
                        DatePicker("Periodo Inicial del Cómputo", selection: $periodoInicial, displayedComponents: .date)
                            .padding(.horizontal)
                            .background(colorCampoSegunTema(selectedTheme))
                            .cornerRadius(8)

                        // Periodo final
                        HStack {
                            Text("Periodo Final del Cómputo:")
                            Spacer()
                            Text(periodoFinal, style: .date)
                                .fontWeight(.semibold)
                                .foregroundColor(colorTextoSegunTema(selectedTheme))
                        }
                        .padding(.horizontal)

                        // Sueldo bruto
                        TextField("Sueldo Bruto Mensual", text: $sueldoBruto)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(colorCampoSegunTema(selectedTheme))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .foregroundColor(colorTextoSegunTema(selectedTheme))

                        // Asignación familiar
                        Toggle("Asignación Familiar (S/. 102.50)", isOn: $asignacionFamiliar)
                            .padding(.horizontal)
                            .foregroundColor(colorTextoSegunTema(selectedTheme))

                        // Gratificación
                        TextField("Gratificación (S/. Julio/Diciembre)", text: $gratificacion)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(colorCampoSegunTema(selectedTheme))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .foregroundColor(colorTextoSegunTema(selectedTheme))

                        HStack {
                            Text("Gratificación Ordinaria:")
                            Spacer()
                            Text(String(format: "S/. %.2f", gratificacionOrdinaria))
                                .fontWeight(.semibold)
                                .foregroundColor(colorTextoSegunTema(selectedTheme))
                        }
                        .padding(.horizontal)

                        // Botón para calcular
                        Button(action: {
                            calcularCTS()
                            mostrarOpciones = true
                        }) {
                            Label("Calcular CTS", systemImage: "scalemass")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(colorBotonSegunTema(selectedTheme))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }

                        if ctsTotal > 0 {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Resultados:")
                                    .font(.headline)
                                    .foregroundColor(colorTextoSegunTema(selectedTheme))
                                Text("Meses Computables: \(mesesComputables)")
                                Text("Días Computables: \(diasComputables)")
                                Text("Total Remuneración Computable: S/. \(String(format: "%.2f", totalRemuneracionComputable))")
                                Text("Total CTS a Depositar: S/. \(String(format: "%.2f", ctsTotal))")
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .foregroundColor(colorTextoSegunTema(selectedTheme))
                        }

                        Spacer()

                        // Pie de página
                        Text("Desarrollado por Jhon Valladolid Castro - 2024")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                    }
                    .padding()
                }
            }
            .navigationTitle("CTS Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(fondoSegunTema(selectedTheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(selectedTheme == .dark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { mostrarSelectorTema = true }) {
                        Image(systemName: "paintpalette")
                            .foregroundColor(colorTextoSegunTema(selectedTheme))
                    }
                }
            }
            .alert("Selecciona un Tema", isPresented: $mostrarSelectorTema) {
                ForEach(Theme.allCases) { tema in
                    Button(tema.rawValue) {
                        selectedTheme = tema
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
            .actionSheet(isPresented: $mostrarOpciones) {
                ActionSheet(
                    title: Text("Opciones de Resultado"),
                    message: Text("¿Qué deseas hacer con los cálculos?"),
                    buttons: [
                        .default(Text("Ver en Pantalla")),
                        .default(Text("Exportar como PDF"), action: exportarPDF),
                        .cancel(Text("Cancelar"))
                    ]
                )
            }
        }
    }

    // Cálculo de CTS
    func calcularCTS() {
        guard let sueldo = Double(sueldoBruto) else { return }

        let asignacion = asignacionFamiliar ? 102.5 : 0.0
        let remuneracionMensual = sueldo + asignacion

        let fechaInicio = max(fechaIngreso, periodoInicial)
        let diasTotales = calcularDias(fechaInicio: fechaInicio, fechaFin: periodoFinal)
        mesesComputables = min(diasTotales / 30, 6)
        diasComputables = diasTotales % 30

        totalRemuneracionComputable = remuneracionMensual + gratificacionOrdinaria

        let valorMensual = totalRemuneracionComputable / 12.0
        let valorDiario = valorMensual / 30.0
        ctsTotal = (Double(mesesComputables) * valorMensual) + (Double(diasComputables) * valorDiario)
    }

    // Exportar a PDF
    func exportarPDF() {
        let content = """
        CALCULADORA DE CTS
        ==================

        Fecha de Ingreso: \(fechaIngreso.formatted())
        Periodo Computable: \(periodoInicial.formatted()) - \(periodoFinal.formatted())

        Sueldo Bruto Mensual: S/. \(sueldoBruto)
        Asignación Familiar: \(asignacionFamiliar ? "S/. 102.50" : "No Aplica")
        Gratificación: S/. \(gratificacion)
        Gratificación Ordinaria: S/. \(String(format: "%.2f", gratificacionOrdinaria))

        Meses Computables: \(mesesComputables)
        Días Computables: \(diasComputables)

        Total Remuneración Computable: S/. \(String(format: "%.2f", totalRemuneracionComputable))
        Total CTS a Depositar: S/. \(String(format: "%.2f", ctsTotal))
        """

        let pdfCreator = PDFCreator()
        pdfCreator.createPDF(content: content, fileName: "CTS_Report.pdf")
    }

    // Cálculo de días
    func calcularDias(fechaInicio: Date, fechaFin: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: fechaInicio, to: fechaFin)
        let diasTotales = (components.year ?? 0) * 360 + (components.month ?? 0) * 30 + (components.day ?? 0)
        return max(diasTotales, 0)
    }

    // Funciones de colores dinámicos
    func fondoSegunTema(_ tema: Theme) -> Color {
        switch tema {
        case .light: return Color.white
        case .dark: return Color.black
        case .auto: return Color(UIColor.systemBackground)
        }
    }

    func colorTextoSegunTema(_ tema: Theme) -> Color {
        switch tema {
        case .light: return Color.blue
        case .dark: return Color.white
        case .auto: return Color.primary
        }
    }

    func colorBotonSegunTema(_ tema: Theme) -> Color {
        switch tema {
        case .light, .auto: return Color.blue
        case .dark: return Color.gray
        }
    }

    func colorCampoSegunTema(_ tema: Theme) -> Color {
        switch tema {
        case .light: return Color(UIColor.systemGray5)
        case .dark: return Color(UIColor.systemGray2)
        case .auto: return Color(UIColor.systemGray4)
        }
    }
}

extension Date {
    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: self)!
    }
}

final class PDFCreator {
    func createPDF(content: String, fileName: String) {
        let pdfMetaData = [
            kCGPDFContextCreator: "CTS Calculator",
            kCGPDFContextAuthor: "Jhon Valladolid Castro",
            kCGPDFContextTitle: "CTS Calculation Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let pdfData = renderer.pdfData { context in
            context.beginPage()
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]
            let attributedText = NSAttributedString(string: content, attributes: textAttributes)
            attributedText.draw(in: CGRect(x: 20, y: 20, width: pageRect.width - 40, height: pageRect.height - 40))
        }

        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfURL = documentDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: pdfURL)
            print("PDF saved to \(pdfURL)")
        } catch {
            print("Could not save PDF file: \(error)")
        }
    }
}

#Preview {
    CTSCalculatorView()
}
