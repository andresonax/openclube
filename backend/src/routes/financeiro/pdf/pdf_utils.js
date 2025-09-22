const mx = 25;
const my = 30;

const zeroPad = (num, places) => String(num).padStart(places, "0");

const cpfCnpj = (v) => {
  //Remove tudo o que não é dígito
  if (!v) return v;
  v = v.replace(/\D/g, "");

  if (v.length < 14) {
    //CPF

    //Coloca um ponto entre o terceiro e o quarto dígitos
    v = v.replace(/(\d{3})(\d)/, "$1.$2");

    //Coloca um ponto entre o terceiro e o quarto dígitos
    //de novo (para o segundo bloco de números)
    v = v.replace(/(\d{3})(\d)/, "$1.$2");

    //Coloca um hífen entre o terceiro e o quarto dígitos
    v = v.replace(/(\d{3})(\d{1,2})$/, "$1-$2");
  } else {
    //CNPJ

    //Coloca ponto entre o segundo e o terceiro dígitos
    v = v.replace(/^(\d{2})(\d)/, "$1.$2");

    //Coloca ponto entre o quinto e o sexto dígitos
    v = v.replace(/^(\d{2})\.(\d{3})(\d)/, "$1.$2.$3");

    //Coloca uma barra entre o oitavo e o nono dígitos
    v = v.replace(/\.(\d{3})(\d)/, ".$1/$2");

    //Coloca um hífen depois do bloco de quatro dígitos
    v = v.replace(/(\d{4})(\d)/, "$1-$2");
  }
  return v;
};

const line = (doc, x, y, size, lineWidth, vertical = false, dashed = false) => {
  doc.lineWidth(lineWidth);
  const line = doc
    .lineCap("butt")
    .moveTo(x + mx, y + my)
    .lineTo(
      vertical ? x + mx : x + mx + size,
      vertical ? y + my + size : y + my
    );

  if (dashed) line.dash(3, { space: 3 });
  line.stroke();
  if (dashed) line.undash();
};

const text = (doc, text, x, y, size = 8, font = "dados") => {
  doc.font(font);
  doc.fontSize(size);
  doc.text(text, mx + x, my + y);
};

const item = (doc, label, value, x, y, width, align = "left") => {
  const height = 25;
  text(doc, label, x + 2, y + 4, 6);
  doc.fontSize(8);
  if (value == undefined || value == null) value = "";
  const textW = doc.widthOfString(value);
  text(
    doc,
    value,
    align == "right"
      ? x + width - 8 - textW
      : align == "center"
      ? x + width / 2 - textW / 2
      : x + 8,
    y + 15
  );

  line(doc, x + width, y, height, 1, true);
};

module.exports = { line, text, item, zeroPad, cpfCnpj };
