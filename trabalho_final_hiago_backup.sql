/*

Trabalho Final - Banco de Dados II

Aluno: Hiago Vinícius

Domínio:
Sistema de Biblioteca

*/

DROP SCHEMA IF EXISTS biblioteca CASCADE;

CREATE SCHEMA biblioteca;

SET search_path TO biblioteca;

CREATE TABLE autor (
    id_autor SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    nacionalidade VARCHAR(50),
    data_nascimento DATE
);

CREATE TABLE editora (
    id_editora SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    cidade VARCHAR(80)
);

CREATE TABLE categoria (
    id_categoria SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE livro (
    id_livro SERIAL PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    ano_publicacao INT CHECK (ano_publicacao >= 1800),
    preco NUMERIC(10,2) CHECK(preco >=0),

    id_autor INT NOT NULL REFERENCES autor(id_autor)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    id_editora INT NOT NULL REFERENCES editora(id_editora)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    id_categoria INT NOT NULL REFERENCES categoria(id_categoria)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE leitor (
    id_leitor SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    data_cadastro DATE NOT NULL
);

CREATE TABLE emprestimo (
    id_emprestimo SERIAL PRIMARY KEY,
    id_leitor INT NOT NULL REFERENCES leitor(id_leitor)
        ON DELETE RESTRICT,

    data_emprestimo DATE NOT NULL,
    data_devolucao DATE,

    CHECK (data_devolucao IS NULL OR data_devolucao >= data_emprestimo)
);

CREATE TABLE item_emprestimo (
    id_item SERIAL PRIMARY KEY,

    id_emprestimo INT REFERENCES emprestimo(id_emprestimo)
        ON DELETE CASCADE,

    id_livro INT REFERENCES livro(id_livro)
        ON DELETE RESTRICT
);

CREATE TABLE log_emprestimo (
    id_log SERIAL PRIMARY KEY,
    descricao TEXT,
    data_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO autor(nome,nacionalidade,data_nascimento) VALUES
('Machado de Assis','Brasileiro','1839-06-21'),
('J.K. Rowling','Britânica','1965-07-31'),
('George Orwell','Britânico','1903-06-25'),
('Clarice Lispector','Brasileira','1920-12-10'),
('J.R.R. Tolkien','Britânico','1892-01-03');

INSERT INTO editora(nome,cidade) VALUES
('Companhia das Letras','São Paulo'),
('Rocco','Rio de Janeiro'),
('Intrínseca','Rio de Janeiro'),
('Saraiva','São Paulo'),
('HarperCollins','Rio de Janeiro');

INSERT INTO categoria(nome) VALUES
('Romance'),
('Fantasia'),
('Ficção'),
('Drama'),
('Suspense');

INSERT INTO livro
(titulo,ano_publicacao,preco,id_autor,id_editora,id_categoria)
VALUES

('Dom Casmurro',1899,49.90,1,1,1),

('Harry Potter e a Pedra Filosofal',1997,69.90,2,2,2),

('1984',1949,55.00,3,3,3),

('A Hora da Estrela',1977,42.00,4,1,4),

('O Hobbit',1937,79.90,5,5,2);

INSERT INTO leitor(nome,email,data_cadastro) VALUES

('Carlos Henrique','carlos@gmail.com','2026-01-15'),

('Mariana Souza','mariana@gmail.com','2026-02-10'),

('João Pedro','joao@gmail.com','2026-02-18'),

('Fernanda Lima','fernanda@gmail.com','2026-03-04'),

('Lucas Almeida','lucas@gmail.com','2026-03-22');

INSERT INTO emprestimo
(id_leitor,data_emprestimo,data_devolucao)
VALUES

(1,'2026-05-01','2026-05-10'),

(2,'2026-05-05','2026-05-15'),

(3,'2026-05-12',NULL),

(4,'2026-05-20',NULL),

(5,'2026-05-25','2026-06-01');

INSERT INTO item_emprestimo
(id_emprestimo,id_livro)
VALUES

(1,1),
(2,2),
(3,3),
(4,5),
(5,4);


-- ALTERAÇÕES NO BANCO (DDL E DML)


-- Adicionando uma coluna de telefone ao cadastro de leitores
ALTER TABLE leitor
ADD COLUMN telefone VARCHAR(20);

-- Renomeando a coluna cidade da editora para cidade_sede
ALTER TABLE editora
RENAME COLUMN cidade TO cidade_sede;

-- Adicionando uma coluna temporária apenas para demonstrar DROP COLUMN
ALTER TABLE livro
ADD COLUMN observacao TEXT;

ALTER TABLE livro
DROP COLUMN observacao;

-- Adicionando uma nova restrição para impedir preço muito alto
ALTER TABLE livro
ADD CONSTRAINT chk_preco_maximo
CHECK (preco <= 500);


-- UPDATES


-- Atualizando telefones dos leitores cadastrados antes de março

UPDATE leitor
SET telefone = '(35)99999-0000'
WHERE data_cadastro < '2026-03-01';

-- Aplicando aumento de 10% aos livros publicados antes de 1950

UPDATE livro
SET preco = preco * 1.10
WHERE ano_publicacao < 1950;


-- CONSULTAS SIMPLES


-- Q1: Quais livros custam mais de R$50?

SELECT titulo, preco
FROM livro
WHERE preco > 50;

-- Q2: Quais leitores foram cadastrados em 2026?

SELECT nome, data_cadastro
FROM leitor
WHERE EXTRACT(YEAR FROM data_cadastro)=2026;

-- Q3: Quais livros pertencem à categoria Fantasia?

SELECT titulo
FROM livro
WHERE id_categoria = (
    SELECT id_categoria
    FROM categoria
    WHERE nome='Fantasia'
);

-- Q4: Quais autores são brasileiros?

SELECT nome
FROM autor
WHERE nacionalidade='Brasileiro'
   OR nacionalidade='Brasileira';

-- Q5: Quais empréstimos ainda não foram devolvidos?

SELECT *
FROM emprestimo
WHERE data_devolucao IS NULL;


-- CONSULTAS COMPLEXAS


-- Q6: Quais leitores pegaram quais livros?

SELECT
l.nome,
lv.titulo,
e.data_emprestimo

FROM leitor l

JOIN emprestimo e
ON l.id_leitor=e.id_leitor

JOIN item_emprestimo ie
ON e.id_emprestimo=ie.id_emprestimo

JOIN livro lv
ON ie.id_livro=lv.id_livro;



-- Q7: Quantos empréstimos cada leitor realizou?

SELECT
l.nome,
COUNT(e.id_emprestimo) AS quantidade

FROM leitor l

LEFT JOIN emprestimo e
ON l.id_leitor=e.id_leitor

GROUP BY l.nome

HAVING COUNT(e.id_emprestimo)>=1;



-- Q8: Quais livros possuem preço acima da média da sua própria categoria?

SELECT
l1.titulo,
l1.preco
FROM livro l1
WHERE l1.preco >
(
    SELECT AVG(l2.preco)
    FROM livro l2
    WHERE l2.id_categoria = l1.id_categoria
);



-- Q9: Ranking de livros por preço

SELECT

titulo,

preco,

RANK() OVER(ORDER BY preco DESC) AS ranking

FROM livro;



-- Q10: União entre autores e leitores

SELECT nome,'Autor' AS tipo
FROM autor

UNION

SELECT nome,'Leitor'
FROM leitor;


-- VIEWS


-- View 1: Livros com autor e categoria

CREATE VIEW vw_livros AS
SELECT
    l.id_livro,
    l.titulo,
    a.nome AS autor,
    c.nome AS categoria,
    l.preco
FROM livro l
JOIN autor a ON l.id_autor = a.id_autor
JOIN categoria c ON l.id_categoria = c.id_categoria;

SELECT * FROM vw_livros;


-- View 2: Empréstimos realizados

CREATE VIEW vw_emprestimos AS
SELECT
    le.nome AS leitor,
    li.titulo AS livro,
    e.data_emprestimo,
    e.data_devolucao
FROM emprestimo e
JOIN leitor le ON e.id_leitor = le.id_leitor
JOIN item_emprestimo ie ON e.id_emprestimo = ie.id_emprestimo
JOIN livro li ON ie.id_livro = li.id_livro;

SELECT * FROM vw_emprestimos;


-- View Materializada

CREATE MATERIALIZED VIEW mv_total_emprestimos AS
SELECT
    l.nome,
    COUNT(e.id_emprestimo) AS total
FROM leitor l
LEFT JOIN emprestimo e
ON l.id_leitor = e.id_leitor
GROUP BY l.nome;

SELECT * FROM mv_total_emprestimos;


-- Inserindo um novo empréstimo para demonstrar a atualização

INSERT INTO emprestimo(id_leitor,data_emprestimo,data_devolucao)
VALUES
(1,'2026-06-20',NULL);

-- Antes do refresh (não muda)

SELECT * FROM mv_total_emprestimos;

-- Atualizando a view materializada

REFRESH MATERIALIZED VIEW mv_total_emprestimos;

-- Depois do refresh

SELECT * FROM mv_total_emprestimos;


-- TRIGGERS


-- Trigger BEFORE: impede inserir livro com preço negativo

CREATE OR REPLACE FUNCTION fn_validar_preco()
RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.preco < 0 THEN
        RAISE EXCEPTION 'O preço do livro não pode ser negativo.';
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_preco
BEFORE INSERT OR UPDATE
ON livro
FOR EACH ROW
EXECUTE FUNCTION fn_validar_preco();


-- Demonstração da trigger BEFORE

SELECT * FROM livro;


-- INSERT INTO livro
-- (titulo,ano_publicacao,preco,id_autor,id_editora,id_categoria)
-- VALUES
-- ('Livro Inválido',2026,-10,1,1,1);


-- Trigger AFTER


CREATE OR REPLACE FUNCTION fn_log_emprestimo()
RETURNS TRIGGER AS
$$
BEGIN

    INSERT INTO log_emprestimo(descricao)
    VALUES
    ('Novo empréstimo registrado para o leitor ID ' || NEW.id_leitor);

    RETURN NEW;

END;
$$
LANGUAGE plpgsql;


CREATE TRIGGER trg_log_emprestimo

AFTER INSERT

ON emprestimo

FOR EACH ROW

EXECUTE FUNCTION fn_log_emprestimo();



-- Demonstração

SELECT * FROM log_emprestimo;

INSERT INTO emprestimo
(id_leitor,data_emprestimo,data_devolucao)
VALUES
(2,'2026-06-25',NULL);

SELECT * FROM log_emprestimo;


-- FUNCTION


CREATE OR REPLACE FUNCTION fn_total_emprestimos(p_id_leitor INT)
RETURNS INT AS
$$
DECLARE
    total INT := 0;
BEGIN

    SELECT COUNT(*)
    INTO total
    FROM emprestimo
    WHERE id_leitor = p_id_leitor;

    IF total IS NULL THEN
        total := 0;
    END IF;

    RETURN total;

END;
$$
LANGUAGE plpgsql;

-- Demonstração da função

SELECT fn_total_emprestimos(1);



-- TRANSAÇÃO


-- Estado antes da transação

SELECT * FROM categoria;

BEGIN;

INSERT INTO categoria(nome)
VALUES ('Biografia');

INSERT INTO categoria(nome)
VALUES ('Tecnologia');

ROLLBACK;

-- Comprovando que nada foi salvo

SELECT * FROM categoria;

BEGIN;

INSERT INTO categoria(nome)
VALUES ('Biografia');

INSERT INTO categoria(nome)
VALUES ('Tecnologia');

COMMIT;

-- Estado final

SELECT * FROM categoria;