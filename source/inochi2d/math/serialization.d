module inochi2d.math.serialization;
import inochi2d.fmt.serialize;
import gl3n.linalg;
import gl3n.util;

/**
    Serializes any size of vector
*/
void serialize(V, S)(V value, ref S serializer) if(is_vector!V) {
    auto state = serializer.arrayBegin();
    static foreach(i; 0..V.dimension) {
        serializer.elemBegin;
        serializer.putValue(value.vector[i]);
    }
    serializer.arrayEnd(state);
}

/**
    Serializes any size of matrix
*/
void serialize(T, S)(T matr, ref S serializer) if(is_matrix!T) {
    auto state = serializer.arrayBegin();
    static foreach(y; 0..T.rows) {
        static foreach(x; 0..T.cols) {
            serializer.elemBegin;
            serializer.putValue(matr.matrix[x][y]);
        }
    }
    serializer.arrayEnd(state);
}

SerdeException deserialize(V)(ref V value, Fghj data) if (is_vector!V) {
    int i = 0;
    foreach(val; data.byElement) {
        val.deserializeValue(value.vector[i++]);
    }
    return null;
}

bool isEmpty(Fghj value) {
    return value == Fghj.init;
}