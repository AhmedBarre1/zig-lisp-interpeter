const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

const Token = struct {
    token_type: []const u8,
    val: []const u8,
    allocator: Allocator,

    pub fn deinit(self: *Token) void {
        self.allocator.free(self.token_type);
        self.allocator.free(self.val);
    }

    pub fn add(token_type: []const u8, val: []const u8, allocator: Allocator) !Token {
        const tok_type = try allocator.dupe(u8, token_type);
        const vals = try allocator.dupe(u8, val);

        return Token{ .token_type = tok_type, .val = vals, .allocator = allocator };
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    try tokenize("(first (1))", allocator);
}

pub fn tokenize(input: []const u8, allocator: Allocator) !void {
    var tokenizedList = std.ArrayList(u8).init(allocator);
    defer tokenizedList.deinit();

    var astList = std.ArrayList(Token).init(allocator);
    defer astList.deinit();

    for (input) |each| {
        if (each == '(') {
            try tokenizedList.append(' ');
            try tokenizedList.append('(');
            try tokenizedList.append(' ');
        } else if (each == ')') {
            try tokenizedList.append(' ');
            try tokenizedList.append(')');
            try tokenizedList.append(' ');
        } else try tokenizedList.append(each);
    }

    const splitWords = std.mem.split(u8, tokenizedList.items, " ");
    const resp = try parenthesize(splitWords, allocator);

    for (resp.items) |*item| {
        print("Token{{ token_type:{s}, val:{s} }}", .{ item.token_type, item.val });
        defer item.deinit();
    }
}

pub fn parenthesize(words_in: std.mem.SplitIterator(u8, .sequence), allocator: Allocator) !std.ArrayList(Token) {
    var list = std.ArrayList(Token).init(allocator);
    var words = words_in;
    const lit = "lit";
    const id = "id";

    while (words.next()) |word| {
        if (!std.mem.eql(u8, word, "")) {
            if (isAlphaSlice(word)) {
                print(" [{s}] ", .{word});
                const token = try Token.add(id, word, allocator);
                try list.append(token);
            } else if (isDigitSlice(word)) {
                print(" num [{s}] ", .{word});
                const token = try Token.add(lit, word, allocator);
                try list.append(token);
            }
        }
    }
    return list;
}

fn isAlphaSlice(word: []const u8) bool {
    if (word.len == 0) return false;
    for (word) |c| {
        if (!std.ascii.isAlphabetic(c)) {
            return false;
        }
    }
    return true;
}

fn isDigitSlice(word: []const u8) bool {
    for (word) |c| {
        if (!std.ascii.isDigit(c)) {
            return false;
        }
    }
    return true;
}
