<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<link rel="stylesheet" href="CSS/style.css">
<%
    // Conexión a la base de datos y obtención del número de cheque
    int numeroCheque = 1000;
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/proyecto2", "root", "");

        // Obtener y actualizar el número de cheque
        pstmt = conn.prepareStatement("SELECT ultimo_numero FROM numeracion_cheques ORDER BY id DESC LIMIT 1");
        rs = pstmt.executeQuery();

        if (rs.next()) {
            numeroCheque = rs.getInt("ultimo_numero") + 1;

            // Actualizar el número en la base de datos
            pstmt = conn.prepareStatement("INSERT INTO numeracion_cheques (ultimo_numero) VALUES (?)");
            pstmt.setInt(1, numeroCheque);
            pstmt.executeUpdate();
        }

    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Emisión de Cheque - Banco Nacional</title>
    <link rel="stylesheet" href="CSS/style.css">
</head>
<body>
<div class="cheque-container">
    <div class="cheque-header">
        <div class="banco-info">
            <h1>BANCO NACIONAL</h1>
            <p class="sucursal">Sucursal Principal</p>
        </div>
        <div class="cheque-number">
            <strong>N°: <span class="numero-cheque"><%= numeroCheque %></span></strong>
        </div>
    </div>

    <!-- Formulario principal -->
    <form action="ProcesarCheque.jsp" method="post" onsubmit="return validarFormulario()">
        <input type="hidden" name="numeroCheque" value="<%= numeroCheque %>">

        <!-- Fecha -->
        <div class="fecha-section">
            <label>Fecha:</label>
            <input type="date" id="fecha" name="fecha" required class="fecha-input">
            <input type="hidden" id="fechaHidden" name="fechaHidden">
        </div>

        <!-- Beneficiario -->
        <div class="campo-cheque">
            <div class="etiqueta">Páguese a la orden de:</div>
            <div class="valor">
                <input type="text" id="beneficiario" name="beneficiario"
                       onkeypress="soloLetrasYEspacios(event)" required
                       class="input-large" placeholder="Nombre completo del beneficiario">
            </div>
        </div>

        <!-- Emisor -->
        <div class="campo-cheque">
            <div class="etiqueta">Emisor:</div>
            <div class="valor">
                <input type="text" id="emisor" name="emisor"
                       onkeypress="soloLetrasYEspacios(event)" required
                       class="input-large" placeholder="Nombre completo del emisor">
            </div>
        </div>

        <!-- Monto -->
        <div class="campo-cheque">
            <div class="etiqueta">La suma de:</div>
            <div class="valor">
                <!-- oninput usa onMontoInput para sanitizar mientras escribe; onblur formatea a 2 decimales -->
                <input type="text" id="monto" name="monto"
                       onkeypress="soloNumeros(event)"
                       oninput="onMontoInput(this)"
                       onblur="formatMonto(this)"
                       required class="input-monto" placeholder="0.00">
            </div>
        </div>

        <!-- Monto en letras -->
        <div class="campo-cheque">
            <div class="etiqueta">Monto en letras:</div>
            <div class="valor">
                <textarea id="letras" name="letras" readonly class="textarea-letras"></textarea>
            </div>
        </div>

        <!-- Detalle y Objeto del gasto -->
        <div class="campo-cheque">
            <div class="etiqueta">Concepto:</div>
            <div class="valor">
                <textarea id="detalle" name="detalle" placeholder="Detalle del pago" class="textarea-concepto"></textarea>
            </div>
        </div>

        <div class="campo-cheque">
            <div class="etiqueta">Objeto del gasto:</div>
            <div class="valor">
                <input type="text" id="objeto" name="objeto"
                       onkeypress="soloLetrasNumerosYEspacios(event)"
                       class="input-large" placeholder="Objeto del gasto">
            </div>
        </div>

        <!-- Firmas (solo visual) -->
        <div class="seccion-firmas-completa">
            <div class="campos-firmas">
                <div class="campo-firma-linea firma-emisor">
                    <div class="etiqueta-firma">Firma del Emisor</div>
                    <div class="linea-firma-solida"></div>
                    <div class="texto-firma">__________________________________________</div>
                </div>
                <div class="campo-firma-linea firma-beneficiario">
                    <div class="etiqueta-firma">Firma del Beneficiario</div>
                    <div class="linea-firma-solida"></div>
                    <div class="texto-firma">__________________________________________</div>
                </div>
            </div>
        </div>

        <!-- Botón de envío -->
        <button type="submit" class="btn-emitir">Emitir Cheque</button>
    </form>
</div>

<script>
    // --- Validaciones de teclado ---
    function soloLetrasYEspacios(e) {
        const key = e.key;
        if (key === 'Backspace' || key === 'Delete' || key === 'ArrowLeft' || key === 'ArrowRight' || key === 'Tab') return;
        if (!/^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]$/.test(key)) e.preventDefault();
    }
    function soloLetrasNumerosYEspacios(e) {
        const key = e.key;
        if (key === 'Backspace' || key === 'Delete' || key === 'ArrowLeft' || key === 'ArrowRight' || key === 'Tab') return;
        if (!/^[a-zA-ZáéíóúÁÉÍÓÚñÑ0-9\s\-]$/.test(key)) e.preventDefault();
    }
    function soloNumeros(e) {
        const key = e.key;
        if (key === 'Backspace' || key === 'Delete' || key === 'ArrowLeft' || key === 'ArrowRight' || key === 'Tab') return;
        // Allow only digits and the dot; only one dot permitted (extra dots blocked here)
        if (!/[0-9.]/.test(key)) { e.preventDefault(); return; }
        const el = e.target;
        if (key === '.' && el.value.includes('.')) e.preventDefault();
    }

    

    // --- Conversión número a letras (maneja centavos 01..99; corrige centavos==100) ---
    function numeroALetras(num) {
        const unidades = ["", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve"];
        const decenas = ["", "diez", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa"];
        const especiales = {11:"once",12:"doce",13:"trece",14:"catorce",15:"quince",16:"dieciséis",17:"diecisiete",18:"dieciocho",19:"diecinueve"};
        const centenas = ["", "cien", "doscientos", "trescientos", "cuatrocientos", "quinientos", "seiscientos", "setecientos", "ochocientos", "novecientos"];

        function convertirMenoresDeMil(n) {
            let texto = "";
            let c = Math.floor(n / 100);
            let d = Math.floor((n % 100) / 10);
            let u = n % 10;
            if (c > 0) texto += (c === 1 && d + u > 0 ? "ciento " : centenas[c] + " ");
            if (d === 1 && u > 0) texto += especiales[d * 10 + u];
            else {
                if (d > 0) texto += decenas[d];
                if (u > 0 && d > 0) texto += " y ";
                if (u > 0) texto += unidades[u];
            }
            return texto.trim();
        }

        function convertirEntero(n) {
            if (n === 0) return "cero";
            if (n > 999999999) return "número demasiado grande";
            let partes = [];
            const secciones = [{valor: 1000000}, {valor: 1000}, {valor: 1}];
            for (let sec of secciones) {
                let cantidad = Math.floor(n / sec.valor);
                if (cantidad > 0) {
                    if (sec.valor === 1000000)
                        partes.push(cantidad === 1 ? "un millón" : convertirEntero(cantidad) + " millones");
                    else if (sec.valor === 1000)
                        partes.push(cantidad === 1 ? "mil" : convertirEntero(cantidad) + " mil");
                    else
                        partes.push(convertirMenoresDeMil(cantidad)
                            .replace(/\buno\b/g, "un")
                            .replace(/\bveintiuno\b/g, "veintiún"));
                }
                n = n % sec.valor;
            }
            return partes.join(" ").trim();
        }

        // lógica principal: redondear a 2 decimales y obtener enteros/centavos
        num = Number(num);
        if (isNaN(num)) return "";
        num = Math.round(num * 100) / 100; // asegurar 2 decimales reales

        let enteros = Math.floor(num);
        let centavos = Math.round((num - enteros) * 100);

        // Si redondeo produce 100 centavos => convertir a 1 balboa
        if (centavos === 100) { enteros += 1; centavos = 0; }

        let texto = "";

        if (enteros === 0 && centavos > 0) {
            // Solo centavos (ej: 0.10 -> "diez centavos")
            texto = convertirEntero(centavos) + (centavos === 1 ? " centavo" : " centavos");
        } else {
            // Con balboas
            texto = convertirEntero(enteros);
            texto += (enteros === 1 ? " balboa" : " balboas");
            if (centavos > 0) {
                texto += " con " + convertirEntero(centavos) + (centavos === 1 ? " centavo" : " centavos");
            }
        }

        return texto.trim();
    }

    function actualizarLetras() {
        let monto = document.getElementById("monto").value;
        if (monto === "" || isNaN(monto)) {
            document.getElementById("letras").value = "";
            return;
        }

        let num = parseFloat(monto);
        if (num < 0.00 || num > 999999.99) {
            document.getElementById("letras").value = "Monto fuera de rango (0.01 - 999,999.99)";
            return;
        }

        let texto = numeroALetras(num);
        document.getElementById("letras").value = texto.charAt(0).toUpperCase() + texto.slice(1);
    }

    // --- Validaciones finales antes de enviar ---
      // --- Validar formulario ---
    function validarFormulario() {
        let beneficiario = document.getElementById("beneficiario").value.trim();
        let emisor = document.getElementById("emisor").value.trim();
        let monto = document.getElementById("monto").value.trim();
        let fecha = document.getElementById("fecha").value.trim();

        if (!beneficiario) { alert("El campo Beneficiario es obligatorio"); return false; }
        if (!emisor) { alert("El campo Emisor es obligatorio"); return false; }
        if (!monto) { alert("El campo Monto es obligatorio"); return false; }
        if (!fecha) { alert("El campo Fecha es obligatorio"); return false; }

        let num = parseFloat(monto);
        if (isNaN(num) || num < 0.00 || num > 999999.99) {
            alert("Ingrese un monto válido entre 0.01 y 999,999.99");
            return false;
        }

        // Actualizar hidden para asegurar que llegue la fecha
        document.getElementById('fechaHidden').value = fecha;
        return true;
    }

   // --- Limitar a dos decimales ---
    const montoInput = document.getElementById("monto");

    montoInput.addEventListener("input", function() {
        // Eliminar caracteres no válidos
        let val = this.value.replace(/[^0-9.]/g, '');
        let parts = val.split('.');

        // Permitir solo un punto decimal
        if (parts.length > 2) {
            val = parts[0] + '.' + parts[1];
        }

        // Limitar los enteros a 6 dígitos (máx. 999999)
        if (parts[0].length > 6) {
            parts[0] = parts[0].substring(0, 6);
            val = parts.join('.');
        }

        // Limitar decimales a 2 dígitos
        if (parts[1]?.length > 2) {
            parts[1] = parts[1].substring(0, 2);
            val = parts.join('.');
        }

        // Eliminar ceros innecesarios al inicio (excepto si es 0.x)
        if (parts[0].length > 1 && parts[0].startsWith('0') && !val.startsWith('0.')) {
            parts[0] = parts[0].replace(/^0+/, '');
            val = parts.join('.');
        }

        this.value = val;
        actualizarLetras();
    });
    

    // --- Fecha automática ---
    window.onload = function() {
        const today = new Date().toISOString().substr(0, 10);
        document.getElementById('fecha').value = today;
        document.getElementById('fechaHidden').value = today;
    };
</script>
</body>
</html>
