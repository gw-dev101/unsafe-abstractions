program Helloworld;

{$mode objfpc}
{$H+}

function u1(value: byte): string;
begin
  u1 := chr(value);
end;
function u2(value: word): string;
begin
  u2 := chr(value shr 8) + chr(value and $FF);
end;
function u4(value: longword): string;
begin
  u4 := chr(value shr 24) + chr((value shr 16) and $FF) + chr((value shr 8) and $FF) + chr(value and $FF);
end;

type
  TConstantPoolEntry = record
    Tag: byte;
    Data: string;
  end;
type
  TConstantPool = array of TConstantPoolEntry;


function utf8(value: string; var constant_pool: TConstantPool): word;
var
  index: word;
begin
  index := Length(constant_pool);
  SetLength(constant_pool, index + 1);
  constant_pool[index].Tag := 1;
  constant_pool[index].Data := value;
  utf8 := index;
end;

function string_info(value_index: word; var constant_pool: TConstantPool): word;
var
  index: word;
begin
  index := Length(constant_pool);
  SetLength(constant_pool, index + 1);
  constant_pool[index].Tag := 8;
  constant_pool[index].Data := u2(value_index);
  string_info := index;
end;

function class_info(name_index: word; var constant_pool: TConstantPool): word;
var
  index: word;
begin
  index := Length(constant_pool);
  SetLength(constant_pool, index + 1);
  constant_pool[index].Tag := 7;
  constant_pool[index].Data := u2(name_index);
  class_info := index;
end;

function name_and_type(name_index, descriptor_index: word; var constant_pool: TConstantPool): word;
var
  index: word;
begin
  index := Length(constant_pool);
  SetLength(constant_pool, index + 1);
  constant_pool[index].Tag := 12;
  constant_pool[index].Data := u2(name_index) + u2(descriptor_index);
  name_and_type := index;
end;

function field_ref(class_index, name_type_index: word; var constant_pool: TConstantPool): word;
var
  index: word;
begin
  index := Length(constant_pool);
  SetLength(constant_pool, index + 1);
  constant_pool[index].Tag := 9;
  constant_pool[index].Data := u2(class_index) + u2(name_type_index);
  field_ref := index;
end;
function method_ref(class_index, name_type_index: word; var constant_pool: TConstantPool): word;
var
  index: word;
begin
  index := Length(constant_pool);
  SetLength(constant_pool, index + 1);
  constant_pool[index].Tag := 10;
  constant_pool[index].Data := u2(class_index) + u2(name_type_index);
  method_ref := index;
end;

function generate_class_file: string;
var
  constant_pool: TConstantPool;
  hello, object_class, system_class, print_stream: word;
  main_name, main_descriptor, out_type, println_type: word;
  system_out, println, message, code_name: word;
  pool_bytes, bytecode, code_attribute, main_method, class_file: string;
  i: integer;
begin
  SetLength(constant_pool, 1); // Initialize constant pool with a dummy entry
  hello := class_info(utf8('HelloWorld', constant_pool), constant_pool);
  object_class := class_info(utf8('java/lang/Object', constant_pool), constant_pool);
  system_class := class_info(utf8('java/lang/System', constant_pool), constant_pool);
  print_stream := class_info(utf8('java/io/PrintStream', constant_pool), constant_pool);
  main_name := utf8('main', constant_pool);
  main_descriptor := utf8('([Ljava/lang/String;)V', constant_pool);
  out_type := name_and_type(utf8('out', constant_pool), utf8('Ljava/io/PrintStream;', constant_pool), constant_pool);
  println_type := name_and_type(utf8('println', constant_pool), utf8('(Ljava/lang/String;)V', constant_pool), constant_pool);
  system_out := field_ref(system_class, out_type, constant_pool);
  println := method_ref(print_stream, println_type, constant_pool);
  message := string_info(utf8('Hello, world!', constant_pool), constant_pool);
  code_name := utf8('Code', constant_pool);

  { Serialize constant pool }
  pool_bytes := u2(Length(constant_pool));

  for i := 1 to Length(constant_pool) - 1 do
  begin
    pool_bytes := pool_bytes + u1(constant_pool[i].Tag);

    if constant_pool[i].Tag = 1 then
      pool_bytes := pool_bytes
        + u2(Length(constant_pool[i].Data))
        + constant_pool[i].Data
    else
      pool_bytes := pool_bytes + constant_pool[i].Data;
  end;

  { getstatic System.out
    ldc message
    invokevirtual println
    return }
  bytecode :=
      u1($B2) + u2(system_out)
    + u1($12) + u1(message)
    + u1($B6) + u2(println)
    + u1($B1);

  code_attribute :=
      u2(2)                       { max_stack }
    + u2(1)                       { max_locals }
    + u4(Length(bytecode))
    + bytecode
    + u2(0)                       { exception_table_length }
    + u2(0);                      { attributes_count }

  main_method :=
      u2($0009)                   { public static }
    + u2(main_name)
    + u2(main_descriptor)
    + u2(1)                       { attributes_count }
    + u2(code_name)
    + u4(Length(code_attribute))
    + code_attribute;

  class_file :=
      u4($CAFEBABE)
    + u2(0)                       { minor_version }
    + u2(52)                      { major_version: Java 8 }
    + pool_bytes
    + u2($0021)                   { public + super }
    + u2(hello)
    + u2(object_class)
    + u2(0)                       { interfaces_count }
    + u2(0)                       { fields_count }
    + u2(1)                       { methods_count }
    + main_method
    + u2(0);                      { class attributes_count }

  generate_class_file := class_file;
end;
var
  class_data: string;
  var f: file;
begin
  { Generate the class file and write it to disk }
  class_data := generate_class_file;
  AssignFile(f, 'HelloWorld.class');
  Rewrite(f, 1);
  BlockWrite(f, class_data[1], Length(class_data));
  CloseFile(f);
end.
